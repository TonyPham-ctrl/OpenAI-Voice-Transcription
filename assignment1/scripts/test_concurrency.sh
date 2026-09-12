#!/usr/bin/env bash
# Concurrency: overlapping uploads must run in parallel, page and API queries must not wait
# behind them, and the token counters must stay exact.
# Every fake OpenAI call takes $UPLOAD_DELAY seconds, standing in for real network time.
source "$(dirname "$0")/lib.sh"

UPLOADS="${UPLOADS:-20}"
UPLOAD_DELAY="${UPLOAD_DELAY:-3}"
MAX_QUERY_SECONDS="${MAX_QUERY_SECONDS:-1.0}"
BURST="${BURST:-100}"

start_fake_openai "$UPLOAD_DELAY"
start_app
make_audio "$WORK_DIR/audio.webm"

request GET /api/v1/admin/uptime # warm-up so first-request startup cost doesn't skew timings

section "$UPLOADS overlapping uploads (each OpenAI call takes ${UPLOAD_DELAY}s)"
start=$(now)
upload_pids=()
for i in $(seq 1 "$UPLOADS"); do
    curl -s -D "$WORK_DIR/upload.$i.headers" -o "$WORK_DIR/upload.$i.body" -w '%{http_code} %{time_total}' \
        -F "file=@$WORK_DIR/audio.webm;type=audio/webm" \
        "$BASE/api/v1/transcribe" > "$WORK_DIR/upload.$i.meta" &
    upload_pids+=($!)
done
sleep 0.5

section "Queries sent while the uploads are still in flight (limit ${MAX_QUERY_SECONDS}s each)"
for path in /api/v1/admin/uptime /api/v1/global/stats /api/v1/admin/running / /app.js /styles.css; do
    request GET "$path"
    if [ "$STATUS" = 200 ] && lt "$TIME" "$MAX_QUERY_SECONDS"; then
        pass "GET $path → 200 in ${TIME}s"
    else
        fail "GET $path → $STATUS in ${TIME}s (want 200 in under ${MAX_QUERY_SECONDS}s)"
    fi
done
queries_done=$(elapsed_since "$start")
if lt "$queries_done" "$UPLOAD_DELAY"; then
    pass "all queries finished at ${queries_done}s, before any upload could finish (${UPLOAD_DELAY}s)"
else
    fail "queries finished at ${queries_done}s, so they didn't overlap the uploads"
fi

wait "${upload_pids[@]}"
wall=$(elapsed_since "$start")

section "Upload results"
ok=0
for i in $(seq 1 "$UPLOADS"); do
    read -r code t < "$WORK_DIR/upload.$i.meta"
    check_leak "$WORK_DIR/upload.$i.headers" "$WORK_DIR/upload.$i.body"
    if [ "$code" = 200 ] && grep -q '"transcribedText"' "$WORK_DIR/upload.$i.body"; then
        ok=$((ok + 1))
    else
        fail "upload #$i → $code after ${t}s" "body: $(head -c 300 "$WORK_DIR/upload.$i.body")"
    fi
done
if [ "$ok" -eq "$UPLOADS" ]; then pass "all $UPLOADS uploads → 200 with transcribedText"; fi

limit=$(awk -v d="$UPLOAD_DELAY" 'BEGIN { print d * 2 }')
if lt "$wall" "$limit"; then
    pass "all $UPLOADS uploads finished in ${wall}s total (one at a time would take ~$((UPLOADS * UPLOAD_DELAY))s)"
else
    fail "uploads took ${wall}s total; expected under ${limit}s if they ran in parallel"
fi

section "Token counters stay exact under concurrent updates"
request GET /api/v1/global/stats
in_tokens=$(json_field inputTokens)
out_tokens=$(json_field outputTokens)
if [ "$in_tokens" = $((UPLOADS * FAKE_INPUT_TOKENS)) ] && [ "$out_tokens" = $((UPLOADS * FAKE_OUTPUT_TOKENS)) ]; then
    pass "inputTokens=$in_tokens outputTokens=$out_tokens after $UPLOADS concurrent uploads"
else
    fail "expected inputTokens=$((UPLOADS * FAKE_INPUT_TOKENS)) outputTokens=$((UPLOADS * FAKE_OUTPUT_TOKENS))" \
        "got inputTokens=$in_tokens outputTokens=$out_tokens"
fi

section "Burst of $BURST simultaneous API queries"
start=$(now)
seq 1 "$BURST" | xargs -P "$BURST" -I{} \
    curl -s -o /dev/null -w '%{http_code}\n' "$BASE/api/v1/admin/uptime" > "$WORK_DIR/burst.codes"
burst_wall=$(elapsed_since "$start")
ok=$(grep -c '^200$' "$WORK_DIR/burst.codes")
if [ "$ok" -eq "$BURST" ]; then
    pass "$ok/$BURST → 200 in ${burst_wall}s"
else
    fail "only $ok/$BURST → 200" "codes: $(sort "$WORK_DIR/burst.codes" | uniq -c | xargs)"
fi

finish
