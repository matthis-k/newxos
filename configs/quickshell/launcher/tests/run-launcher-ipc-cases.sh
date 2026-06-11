#!/usr/bin/env bash
# Launcher IPC regression test runner
# Usage: ./run-launcher-ipc-cases.sh [--verbose] [--endpoint search|visual|pipeline|shape]
set -euo pipefail

VERBOSE=false
ENDPOINT="runCases"
IPC="newshell ipc call query"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose|-v) VERBOSE=true; shift ;;
    --endpoint) ENDPOINT="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "=== Launcher IPC Regression Cases ==="
echo "Endpoint: $ENDPOINT"
echo ""

if [ "$ENDPOINT" = "runCases" ]; then
  echo "Running all regression cases via runCases endpoint..."
  RESULT=$($IPC runCases 2>/dev/null || echo '{"error":"IPC call failed"}')
  echo "$RESULT" | jq '.summary // {error: "no summary"}'
  echo ""
  echo "Detailed results:"
  echo "$RESULT" | jq '.results[] | {query, totalRows, visibleRows, topTitle, topScore, wallMs: .timings.totalMs}'
  exit 0
fi

# Define regression queries
QUERIES=(
  "?" "? " "?au"
  "zen" "zen " "zen priv" "zen win" "zen browser" "zen new"
  "wifi" "wifi " "wifi on" "wifi off" "wifi toggle" "toggle wifi"
  "wo" "wt"
  ":" ":wifi" ":wifi " ":wifi on" ":db wifi"
  "@apps" "@apps zen" "@web nix"
  "web nix" "web !gh nix"
  "db wifi" "dashboard wifi"
  "au" "aud" "audi" "audio"
  "en" "screen" "session"
  "newxos" "vpn of"
  "notes" "/tmp"
)

echo "Query count: ${#QUERIES[@]}"
echo ""

FAILED=0
PASSED=0

for q in "${QUERIES[@]}"; do
  if $VERBOSE; then
    echo -n "[$ENDPOINT] \"$q\"... "
  fi

  RESULT=$($IPC "$ENDPOINT" "$q" 2>/dev/null || echo '{"error":"IPC call failed"}')

  if echo "$RESULT" | jq -e '.error' >/dev/null 2>&1; then
    echo "FAIL: $q - $(echo "$RESULT" | jq -r '.error')"
    FAILED=$((FAILED + 1))
    continue
  fi

  case "$ENDPOINT" in
    search|visual)
      ROWS=$(echo "$RESULT" | jq '[.results[] | select(.ownVisible == true)] | length' 2>/dev/null || echo "0")
      ;;
    pipeline)
      ROWS=$(echo "$RESULT" | jq '.stages.renderedRows // 0' 2>/dev/null || echo "0")
      ;;
    shape)
      ROWS=$(echo "$RESULT" | jq '.totalResults // 0' 2>/dev/null || echo "0")
      ;;
    *)
      ROWS=0
      ;;
  esac

  if $VERBOSE; then
    echo "OK ($ROWS visible rows)"
  fi
  PASSED=$((PASSED + 1))
done

echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"
exit $FAILED
