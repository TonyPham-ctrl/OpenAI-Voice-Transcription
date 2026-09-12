#!/usr/bin/env bash
# Every success and error status the API can return, with the response body shape for each.
# 202 and 409 for shutdown are covered in test_shutdown.sh.
source "$(dirname "$0")/lib.sh"

start_fake_openai 0
start_app
make_audio "$WORK_DIR/audio.webm"

section "200 OK (spec endpoints and the page)"
request GET /api/v1/admin/uptime
expect_status 200 "GET /api/v1/admin/uptime"
expect_json_keys "utcServerStart utcNow serverUptimeSeconds" "uptime"
expect_utc_timestamp utcServerStart "uptime"
expect_utc_timestamp utcNow "uptime"
uptime=$(json_field serverUptimeSeconds)
if awk -v u="$uptime" 'BEGIN { exit !(u + 0 == u && u >= 0) }'; then
    pass "uptime serverUptimeSeconds is a number >= 0 ($uptime)"
else
    fail "uptime serverUptimeSeconds should be a number >= 0" "got: $uptime"
fi

request GET /api/v1/global/stats
expect_status 200 "GET /api/v1/global/stats"
expect_json_keys "inputTokens outputTokens" "stats"

request GET /api/v1/admin/running
expect_status 200 "GET /api/v1/admin/running"

request GET /
expect_status 200 "GET / (index.html)"

request POST /api/v1/transcribe -F "file=@$WORK_DIR/audio.webm;type=audio/webm"
expect_status 200 "POST /api/v1/transcribe (fake OpenAI only answers 200 if it got the right Bearer key)"
expect_json_keys "transcribedText" "transcribe"

section "404 Not Found"
request GET /api/v1/does-not-exist
expect_status 404 "GET /api/v1/does-not-exist"
expect_error_body 404 "Not Found" /api/v1/does-not-exist "404"

section "405 Method Not Allowed"
for endpoint in "GET /api/v1/admin/shutdown" "POST /api/v1/admin/uptime" "POST /api/v1/global/stats" "GET /api/v1/transcribe"; do
    set -- $endpoint
    request "$1" "$2"
    expect_status 405 "$1 $2"
    expect_error_body 405 "Method Not Allowed" "$2" "$1 $2"
done

section "400 Bad Request"
request POST /api/v1/transcribe -F "audio=@$WORK_DIR/audio.webm;type=audio/webm"
expect_status 400 "POST /api/v1/transcribe with no 'file' part"
expect_error_body 400 "Bad Request" /api/v1/transcribe "missing file part"

request POST /api/v1/transcribe -H "Content-Type: application/json" -d '{}'
expect_status 400 "POST /api/v1/transcribe with a non-multipart body"
expect_error_body 400 "Bad Request" /api/v1/transcribe "non-multipart body"

section "413 Payload Too Large (limit is 25MB)"
head -c $((26 * 1024 * 1024)) /dev/zero > "$WORK_DIR/too_big.webm"
request POST /api/v1/transcribe -F "file=@$WORK_DIR/too_big.webm;type=audio/webm"
expect_status 413 "POST /api/v1/transcribe with a 26MB file"
expect_error_body 413 "Payload Too Large" /api/v1/transcribe "413"

section "5xx when OpenAI fails (must not pass OpenAI's error details to the client)"
for upstream in 401 429 500; do
    make_audio "$WORK_DIR/audio_$upstream.webm" "TRIGGER_$upstream"
    request POST /api/v1/transcribe -F "file=@$WORK_DIR/audio_$upstream.webm;type=audio/webm"
    if [ "$STATUS" = 500 ] || [ "$STATUS" = 502 ]; then
        pass "OpenAI returns $upstream → app returns $STATUS"
    else
        fail "OpenAI returns $upstream → expected 500 or 502, got $STATUS" "body: ${BODY:0:300}"
    fi
    expect_json_keys "timestamp status error message path" "upstream $upstream error"
    if grep -qE "Simulated upstream|Incorrect API key" <<< "$BODY"; then
        fail "upstream $upstream: OpenAI's error message was passed through to the client" "body: ${BODY:0:300}"
    else
        pass "upstream $upstream: OpenAI's error details not exposed"
    fi
done

finish
