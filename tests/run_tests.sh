#!/bin/bash
# Feeds each line of tests/valid.txt and tests/invalid.txt to ./english
# one sentence at a time and checks the exit code matches expectations.

set -u
cd "$(dirname "$0")/.."

BIN=./english
PASS=0
FAIL=0

if [ ! -x "$BIN" ]; then
    echo "error: $BIN not found; run 'make' first" >&2
    exit 1
fi

echo "== valid sentences (expect exit code 0) =="
while IFS= read -r line; do
    [ -z "$line" ] && continue
    if echo "$line" | $BIN > /dev/null 2>&1; then
        echo "PASS: $line"
        PASS=$((PASS + 1))
    else
        echo "FAIL (should be valid): $line"
        FAIL=$((FAIL + 1))
    fi
done < tests/valid.txt

echo
echo "== invalid sentences (expect non-zero exit code) =="
while IFS= read -r line; do
    [ -z "$line" ] && continue
    if echo "$line" | $BIN > /dev/null 2>&1; then
        echo "FAIL (should be invalid): $line"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: $line"
        PASS=$((PASS + 1))
    fi
done < tests/invalid.txt

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
