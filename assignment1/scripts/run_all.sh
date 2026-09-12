#!/usr/bin/env bash
# Runs every test script. Usage: scripts/run_all.sh
# Needs java, python3 and curl. Builds the jar first if it's missing or out of date.
# Each script starts its own app on port 18080 against a fake OpenAI on port 18999,
# so it won't clash with an app you have running on 8080, and no real API key is used.
cd "$(dirname "$0")" || exit 1

status=0
for t in test_status_codes.sh test_concurrency.sh test_shutdown.sh; do
    printf '\n########## %s\n' "$t"
    bash "$t" || status=1
done

if [ "$status" -eq 0 ]; then echo; echo "ALL TEST SCRIPTS PASSED"; else echo; echo "SOME TEST SCRIPTS FAILED"; fi
exit "$status"
