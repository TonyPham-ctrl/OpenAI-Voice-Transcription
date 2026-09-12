set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PORT="${APP_PORT:-18080}"
FAKE_PORT="${FAKE_PORT:-18999}"
BASE="http://localhost:$APP_PORT"
FAKE_KEY="sk-test-canary-DO-NOT-LEAK-0123456789"
FAKE_INPUT_TOKENS=10   # per call, must match fake_openai.py
FAKE_OUTPUT_TOKENS=2

WORK_DIR="$(mktemp -d)"
APP_LOG="$WORK_DIR/app.log"
APP_PID=""
FAKE_PID=""
PASSED=0
FAILED=0
LEAKS=0


section() { printf '\n== %s\n' "$1"; }

pass() {
    PASSED=$((PASSED + 1))
    printf '  \033[32mPASS\033[0m %s\n' "$1"
    return 0
}

fail() {
    FAILED=$((FAILED + 1))
    printf '  \033[31mFAIL\033[0m %s\n' "$1"
    if [ -n "${2:-}" ]; then printf '       %s\n' "$2"; fi
    return 0
}


cleanup() {
    if [ -n "$APP_PID" ]; then kill "$APP_PID" 2>/dev/null; wait "$APP_PID" 2>/dev/null; fi
    if [ -n "$FAKE_PID" ]; then kill "$FAKE_PID" 2>/dev/null; wait "$FAKE_PID" 2>/dev/null; fi
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

wait_for() { # url timeout_seconds
    for _ in $(seq 1 $(($2 * 5))); do
        curl -s -o /dev/null "$1" && return 0
        sleep 0.2
    done
    return 1
}

# Builds the jar if it's missing or any source file is newer than it.
ensure_jar() {
    JAR="$(ls "$PROJECT_DIR"/target/assignment1-*.jar 2>/dev/null | head -1)"
    if [ -z "$JAR" ] || [ -n "$(find "$PROJECT_DIR/src" "$PROJECT_DIR/pom.xml" -type f -newer "$JAR" | head -1)" ]; then
        echo "Building jar (unit tests skipped)..."
        (cd "$PROJECT_DIR" && ./mvnw -q -DskipTests package) || { echo "Build failed"; exit 1; }
        JAR="$(ls "$PROJECT_DIR"/target/assignment1-*.jar | head -1)"
    fi
}

start_fake_openai() { # delay_seconds
    FAKE_DELAY="${1:-0}" EXPECTED_KEY="$FAKE_KEY" \
        python3 "$SCRIPT_DIR/fake_openai.py" "$FAKE_PORT" > "$WORK_DIR/fake.log" 2>&1 &
    FAKE_PID=$!
    wait_for "http://127.0.0.1:$FAKE_PORT/" 10 || { echo "Fake OpenAI didn't start:"; cat "$WORK_DIR/fake.log"; exit 1; }
}

start_app() {
    ensure_jar
    if curl -s -o /dev/null "$BASE"; then
        echo "Something is already listening on port $APP_PORT. Stop it or set APP_PORT."
        exit 1
    fi
    OPENAI_API_KEY="$FAKE_KEY" java -jar "$JAR" \
        --server.port="$APP_PORT" \
        --openai.api.url="http://127.0.0.1:$FAKE_PORT/v1/audio/transcriptions" \
        > "$APP_LOG" 2>&1 &
    APP_PID=$!
    wait_for "$BASE/api/v1/admin/running" 60 || { echo "App didn't start. Last log lines:"; tail -40 "$APP_LOG"; exit 1; }
}

# ---------- requests ----------

# request METHOD PATH [extra curl args...]  → sets STATUS, TIME, BODY
# STATUS is 000 if the connection was refused.
request() {
    local method="$1" path="$2"; shift 2
    rm -f "$WORK_DIR/last.headers" "$WORK_DIR/last.body"
    local meta
    meta=$(curl -s -D "$WORK_DIR/last.headers" -o "$WORK_DIR/last.body" \
        -w '%{http_code} %{time_total}' -X "$method" "$@" "$BASE$path")
    STATUS="${meta%% *}"
    TIME="${meta##* }"
    BODY="$(cat "$WORK_DIR/last.body" 2>/dev/null)"
    check_leak "$WORK_DIR/last.headers" "$WORK_DIR/last.body"
}

# Counts any response file that contains the API key.
check_leak() {
    if cat "$@" 2>/dev/null | grep -qF "$FAKE_KEY"; then LEAKS=$((LEAKS + 1)); fi
}

# make_audio FILE [marker]  → random bytes, optionally tagged with a fake_openai.py trigger
make_audio() {
    head -c 20000 /dev/urandom > "$1"
    if [ -n "${2:-}" ]; then printf '%s' "$2" >> "$1"; fi
}

now() { date +%s.%N; }
elapsed_since() { awk -v s="$1" -v e="$(now)" 'BEGIN { printf "%.2f", e - s }'; }
lt() { awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'; }

# ---------- assertions ----------

# Prints a top-level JSON field from $BODY (__MISSING__ / __INVALID__ on problems).
json_field() {
    python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
except Exception:
    print("__INVALID__"); sys.exit()
v = d.get(sys.argv[1], "__MISSING__") if isinstance(d, dict) else "__MISSING__"
print(v if isinstance(v, str) else json.dumps(v))
' "$1" <<< "$BODY"
}

expect_status() { # expected description
    if [ "$STATUS" = "$1" ]; then
        pass "$2 → $STATUS"
    else
        fail "$2 → expected $1, got $STATUS" "body: ${BODY:0:300}"
    fi
}

# The spec sets additionalProperties: false, so the field set must match exactly.
expect_json_keys() { # "field field ..." description
    local got want
    got=$(python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
except Exception:
    print("__INVALID__"); sys.exit()
print(" ".join(sorted(d)) if isinstance(d, dict) else "__NOT_AN_OBJECT__")
' <<< "$BODY")
    want=$(tr ' ' '\n' <<< "$1" | sort | xargs)
    if [ "$got" = "$want" ]; then
        pass "$2 has exactly: $want"
    else
        fail "$2 fields: expected [$want], got [$got]" "body: ${BODY:0:300}"
    fi
}

expect_utc_timestamp() { # field description
    local v
    v=$(json_field "$1")
    if [[ "$v" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?Z$ ]]; then
        pass "$2 $1 is a UTC RFC 3339 timestamp ($v)"
    else
        fail "$2 $1 is not a UTC RFC 3339 timestamp" "got: $v"
    fi
}

# Checks the spec's ErrorResponse shape and values.
expect_error_body() { # status reason path description
    expect_json_keys "timestamp status error message path" "$4"
    expect_utc_timestamp timestamp "$4"
    local s e p
    s=$(json_field status); e=$(json_field error); p=$(json_field path)
    if [ "$s" = "$1" ] && [ "$e" = "$2" ] && [ "$p" = "$3" ]; then
        pass "$4 body: status=$s error=\"$e\" path=$p"
    else
        fail "$4 body: expected status=$1 error=\"$2\" path=$3" "got status=$s error=\"$e\" path=$p"
    fi
}

# Call at the end of every script: key-leak checks, summary, and exit code.
finish() {
    section "API key leak check"
    if [ "$LEAKS" -eq 0 ]; then
        pass "key never appeared in any HTTP response (headers or body)"
    else
        fail "key appeared in $LEAKS HTTP response(s)"
    fi
    if grep -qF "$FAKE_KEY" "$APP_LOG"; then
        fail "key appears in the app log"
    else
        pass "key not in the app log"
    fi
    printf '\n%d passed, %d failed\n' "$PASSED" "$FAILED"
    [ "$FAILED" -eq 0 ]
}
