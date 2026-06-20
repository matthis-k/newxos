#!/usr/bin/env bash
# Launcher IPC regression test runner with semantic assertions
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

# Regression queries with expected behaviors
# Format: "query|expected_min_rows|must_include_title_glob|must_match_semantics_key"
QUERIES=(
  # Zen browser family — should find zen browser controls
  "zen|1|Zen|"
  "zen |1|Zen|"
  "zen priv|1|Private|"
  "zen win|1|Window|"
  "zen browser|1|Zen|"
  # WiFi switch family — should find wifi controls
  "wifi|1|WiFi|"
  "wifi on|1|WiFi|"
  "wifi off|1|WiFi|"
  "wifi toggle|1|WiFi|"
  "wo|1|WiFi|"
  # Math evaluation
  "= 1+2|1||"
  # Session management
  "session|1|Session|"
  # Destructive actions — should appear with risk semantics
  "shutdown|1|Shutdown|shutdown"
  "reboot|1|Reboot|"
  "logout|1|Logout|logout"
  # File path
  "~/newxos|1||"
  # App directive
  "@apps|1|Applications|"
  "@apps zen|1||"
  # Dashboard
  "db wifi|1|WiFi|"
  # Newxos group
  "newxos|1|newxos|"
  "newxos |1|newxos|"
)

echo "Query count: ${#QUERIES[@]}"
echo ""

FAILED=0
PASSED=0

for entry in "${QUERIES[@]}"; do
  IFS='|' read -r q min_rows must_include must_semantics <<< "$entry"
  if $VERBOSE; then
    echo -n "[$ENDPOINT] \"$q\"... "
  fi

  RESULT=$($IPC "$ENDPOINT" "$q" 2>/dev/null || echo '{"error":"IPC call failed"}')

  if echo "$RESULT" | jq -e '.error' >/dev/null 2>&1; then
    echo "FAIL: $q - $(echo "$RESULT" | jq -r '.error')"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Parse results based on endpoint
  case "$ENDPOINT" in
    search|visual)
      VISIBLE_ROWS=$(echo "$RESULT" | jq '[.results[] | select(.ownVisible == true)] | length' 2>/dev/null || echo "0")
      TOP_TITLE=$(echo "$RESULT" | jq -r '.results[0].title // ""' 2>/dev/null || echo "")
      TOP_SEMANTICS=$(echo "$RESULT" | jq -r '.results[0].semantics.activation.mode // ""' 2>/dev/null || echo "")
      ;;
    pipeline)
      VISIBLE_ROWS=$(echo "$RESULT" | jq '.stages.renderedRows // 0' 2>/dev/null || echo "0")
      TOP_TITLE=$(echo "$RESULT" | jq -r '.stages.rows[0].title // ""' 2>/dev/null || echo "")
      TOP_SEMANTICS=$(echo "$RESULT" | jq -r '.stages.rows[0].semantics.activation.mode // ""' 2>/dev/null || echo "")
      ;;
    shape)
      VISIBLE_ROWS=$(echo "$RESULT" | jq '.totalResults // 0' 2>/dev/null || echo "0")
      TOP_TITLE=$(echo "$RESULT" | jq -r '.results[0].title // ""' 2>/dev/null || echo "")
      TOP_SEMANTICS=$(echo "$RESULT" | jq -r '.results[0].semantics.activation.mode // ""' 2>/dev/null || echo "")
      ;;
    *)
      VISIBLE_ROWS=0
      TOP_TITLE=""
      TOP_SEMANTICS=""
      ;;
  esac

  FAIL_REASON=""

  # Check minimum rows
  if [ "$VISIBLE_ROWS" -lt "$min_rows" ] 2>/dev/null; then
    FAIL_REASON="expected >= $min_rows rows, got $VISIBLE_ROWS"
  fi

  # Check must_include title
  if [ -z "$FAIL_REASON" ] && [ -n "$must_include" ]; then
    TITLE_MATCH=$(echo "$TOP_TITLE" | grep -i "$must_include" || true)
    if [ -z "$TITLE_MATCH" ]; then
      FAIL_REASON="expected title containing '$must_include', got '$TOP_TITLE'"
    fi
  fi

  # Check semantic assertion for activation mode
  if [ -z "$FAIL_REASON" ] && [ -n "$must_semantics" ]; then
    case "$must_semantics" in
      shutdown|logout)
        if [ "$TOP_SEMANTICS" != "confirm-and-explicit-prefix" ] && [ "$TOP_SEMANTICS" != "confirm" ]; then
          FAIL_REASON="expected confirm semantics for $must_semantics, got '$TOP_SEMANTICS'"
        fi
        ;;
    esac
  fi

  if [ -n "$FAIL_REASON" ]; then
    echo "FAIL: $q - $FAIL_REASON"
    FAILED=$((FAILED + 1))
  else
    if $VERBOSE; then
      echo "OK ($VISIBLE_ROWS rows, top: '$TOP_TITLE', semantics: '$TOP_SEMANTICS')"
    fi
    PASSED=$((PASSED + 1))
  fi
done

echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"
exit $FAILED
