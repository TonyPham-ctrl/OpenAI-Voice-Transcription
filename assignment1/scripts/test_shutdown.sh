
source "$(dirname "$0")/lib.sh"

UPLOAD_DELAY="${UPLOAD_DELAY:-5}"
SHUTDOWN_REQUESTS="${SHUTDOWN_REQUESTS:-10}"

start_fake_openai "$UPLOAD_DELAY"
start_app
make_audio "$WORK_DIR/audio.webm"

section "Before shutdown"
request GET /api/v1/admin/running
if [ "$BODY" = true ]; then pass "/running → true"; else fail "/running should be true" "got: $BODY"; fi

section "Start an upload that will still be running when shutdown is requested"
curl -s -D "$WORK_DIR/inflight.headers" -o "$WORK_DIR/inflight.body" -w '%{http_code} %{time_total}' \
    -F "file=@$WORK_DIR/audio.webm;type=audio/webm" \
    "$BASE/api/v1/transcribe" > "$WORK_DIR/inflight.meta" &
inflight_pid=$!
sleep 1
pass "upload started (OpenAI call takes ${UPLOAD_DELAY}s)"

section "$SHUTDOWN_REQUESTS simultaneous shutdown requests"
shutdown_pids=()
for i in $(seq 1 "$SHUTDOWN_REQUESTS"); do
    curl -s -D "$WORK_DIR/shutdown.$i.headers" -o "$WORK_DIR/shutdown.$i.body" -w '%{http_code}' \
        -X POST "$BASE/api/v1/admin/shutdown" > "$WORK_DIR/shutdown.$i.code" &
    shutdown_pids+=($!)
done
wait "${shutdown_pids[@]}"

accepted=0
conflicts=0
refused=0
for i in $(seq 1 "$SHUTDOWN_REQUESTS"); do
    STATUS=$(cat "$WORK_DIR/shutdown.$i.code")
    BODY=$(cat "$WORK_DIR/shutdown.$i.body" 2>/dev/null)
    check_leak "$WORK_DIR/shutdown.$i.headers" "$WORK_DIR/shutdown.$i.body"
    case "$STATUS" in
        202)
            accepted=$((accepted + 1))
            expect_json_keys "message" "202 response"
            if [ "$(json_field message)" = "Graceful shutdown requested." ]; then
                pass "202 message is \"Graceful shutdown requested.\""
            else
                fail "202 message wrong" "body: $BODY"
            fi
            ;;
        409)
            conflicts=$((conflicts + 1))
            # One body check is enough; the rest are identical.
            if [ "$conflicts" -eq 1 ]; then expect_error_body 409 "Conflict" /api/v1/admin/shutdown "409 response"; fi
            ;;
        000)
            refused=$((refused + 1))
            ;;
        *)
            fail "shutdown request #$i → unexpected $STATUS" "body: ${BODY:0:300}"
            ;;
    esac
done
echo "  results: $accepted× 202, $conflicts× 409, $refused× connection refused"
if [ "$accepted" -eq 1 ]; then pass "exactly one request was accepted"; else fail "expected exactly one 202, got $accepted"; fi
# 409 is only observable for requests that land before Tomcat stops accepting connections,
# which is why the requests are fired together.
if [ "$conflicts" -ge 1 ]; then pass "overlapping requests got 409 Conflict"; else fail "no request got 409 Conflict"; fi

section "While shutting down"
refused_new=false
for _ in $(seq 1 25); do
    request GET /api/v1/admin/uptime
    if [ "$STATUS" = 000 ]; then refused_new=true; break; fi
    sleep 0.2
done
if $refused_new; then pass "new connections are refused"; else fail "server still accepted new requests 5s after shutdown"; fi

wait "$inflight_pid"
read -r code t < "$WORK_DIR/inflight.meta"
check_leak "$WORK_DIR/inflight.headers" "$WORK_DIR/inflight.body"
if [ "$code" = 200 ] && grep -q '"transcribedText"' "$WORK_DIR/inflight.body"; then
    pass "in-flight upload was allowed to finish → 200 after ${t}s"
else
    fail "in-flight upload → $code after ${t}s (graceful shutdown should let it finish)" \
        "body: $(head -c 300 "$WORK_DIR/inflight.body")"
fi

section "Process exit"
for _ in $(seq 1 80); do
    kill -0 "$APP_PID" 2>/dev/null || break
    sleep 0.5
done
if kill -0 "$APP_PID" 2>/dev/null; then
    fail "app process still running 40s after shutdown was accepted"
else
    wait "$APP_PID"
    exit_code=$?
    APP_PID=""
    if [ "$exit_code" -eq 0 ]; then pass "process exited with code 0"; else fail "process exited with code $exit_code"; fi
fi

finish
