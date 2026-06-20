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
# Format: query|expected_min_rows|must_include_title_glob|activation_mode_check|must_be_executable
# activation_mode_check: confirm, confirm-and-explicit-prefix, normal, blocked, or "" (skip)
# must_be_executable: 1 (must be true), 0 (must be false), or "" (skip)
QUERIES=(
  # Zen browser family — should find zen browser controls
  "zen|1|Zen||"
  "zen |1|Zen||"
  "zen priv|1|Private||"
  "zen win|1|Window||"
  "zen browser|1|Zen||"
  # WiFi switch family — should find wifi controls
  "wifi|1|WiFi||"
  "wifi on|1|WiFi||"
  "wifi off|1|WiFi||"
  "wifi toggle|1|WiFi||"
  "wo|1|WiFi||"
  # Math evaluation
  "= 1+2|1|||"
  # Session management
  "session|1|Session||"
  # Destructive actions — should appear with risk semantics and be non-executable
  "shutdown|1|Shutdown|confirm-and-explicit-prefix|0"
  "reboot|1|Reboot|confirm|0"
  "logout|1|Logout|confirm-and-explicit-prefix|0"
  # File path
  "~/newxos|1|||"
  # App directive
  "@apps|1|Applications||"
  "@apps zen|1|||"
  # Dashboard
  "db wifi|1|WiFi||"
  # Newxos group
  "newxos|1|newxos||"
  "newxos |1|newxos||"
)

echo "Query count: ${#QUERIES[@]}"
echo ""

FAILED=0
PASSED=0

for entry in "${QUERIES[@]}"; do
  IFS='|' read -r q min_rows must_include must_activate must_executable <<< "$entry"
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
      TOP_ACTIVATION=$(echo "$RESULT" | jq -r '.results[0].semantics.activation.mode // ""' 2>/dev/null || echo "")
      TOP_EXECUTABLE=$(echo "$RESULT" | jq -r '.results[0].executable // false' 2>/dev/null || echo "false")
      TOP_TAKEOVER=$(echo "$RESULT" | jq -r '.results[0].semantics.takeover.decision.accepted // false' 2>/dev/null || echo "false")
      TOP_DEFAULT_ACTION=$(echo "$RESULT" | jq -r '.results[0].defaultAction.id // ""' 2>/dev/null || echo "")
      ;;
    pipeline)
      VISIBLE_ROWS=$(echo "$RESULT" | jq '.stages.renderedRows // 0' 2>/dev/null || echo "0")
      TOP_TITLE=$(echo "$RESULT" | jq -r '.stages.rows[0].title // ""' 2>/dev/null || echo "")
      TOP_ACTIVATION=$(echo "$RESULT" | jq -r '.stages.rows[0].semantics.activation.mode // ""' 2>/dev/null || echo "")
      TOP_EXECUTABLE=$(echo "$RESULT" | jq -r '.stages.rows[0].executable // false' 2>/dev/null || echo "false")
      TOP_TAKEOVER=$(echo "$RESULT" | jq -r '.stages.rows[0].semantics.takeover.decision.accepted // false' 2>/dev/null || echo "false")
      TOP_DEFAULT_ACTION=$(echo "$RESULT" | jq -r '.stages.rows[0].defaultAction.id // ""' 2>/dev/null || echo "")
      ;;
    shape)
      VISIBLE_ROWS=$(echo "$RESULT" | jq '.totalResults // 0' 2>/dev/null || echo "0")
      TOP_TITLE=$(echo "$RESULT" | jq -r '.results[0].title // ""' 2>/dev/null || echo "")
      TOP_ACTIVATION=$(echo "$RESULT" | jq -r '.results[0].semantics.activation.mode // ""' 2>/dev/null || echo "")
      TOP_EXECUTABLE=$(echo "$RESULT" | jq -r '.results[0].executable // false' 2>/dev/null || echo "false")
      TOP_TAKEOVER=$(echo "$RESULT" | jq -r '.results[0].semantics.takeover.decision.accepted // false' 2>/dev/null || echo "false")
      TOP_DEFAULT_ACTION=$(echo "$RESULT" | jq -r '.results[0].defaultAction.id // ""' 2>/dev/null || echo "")
      ;;
    *)
      VISIBLE_ROWS=0
      TOP_TITLE=""
      TOP_ACTIVATION=""
      TOP_EXECUTABLE="false"
      TOP_TAKEOVER="false"
      TOP_DEFAULT_ACTION=""
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

  # Check activation mode assertion
  if [ -z "$FAIL_REASON" ] && [ -n "$must_activate" ]; then
    case "$must_activate" in
      confirm-and-explicit-prefix)
        if [ "$TOP_ACTIVATION" != "confirm-and-explicit-prefix" ]; then
          FAIL_REASON="expected activation mode 'confirm-and-explicit-prefix', got '$TOP_ACTIVATION'"
        fi
        ;;
      confirm)
        if [ "$TOP_ACTIVATION" != "confirm" ]; then
          FAIL_REASON="expected activation mode 'confirm', got '$TOP_ACTIVATION'"
        fi
        ;;
      normal)
        if [ "$TOP_ACTIVATION" != "normal" ] && [ -n "$TOP_ACTIVATION" ]; then
          FAIL_REASON="expected activation mode 'normal', got '$TOP_ACTIVATION'"
        fi
        ;;
      blocked)
        if [ "$TOP_ACTIVATION" != "blocked" ]; then
          FAIL_REASON="expected activation mode 'blocked', got '$TOP_ACTIVATION'"
        fi
        ;;
    esac
  fi

  # Check executable assertion
  if [ -z "$FAIL_REASON" ] && [ -n "$must_executable" ]; then
    if [ "$must_executable" = "1" ] && [ "$TOP_EXECUTABLE" != "true" ]; then
      FAIL_REASON="expected executable=true, got $TOP_EXECUTABLE"
    elif [ "$must_executable" = "0" ] && [ "$TOP_EXECUTABLE" != "false" ]; then
      FAIL_REASON="expected executable=false (risk should block at gate), got $TOP_EXECUTABLE"
    fi
  fi

  if [ -n "$FAIL_REASON" ]; then
    echo "FAIL: $q - $FAIL_REASON"
    if $VERBOSE; then
      echo "  Context: activation=$TOP_ACTIVATION executable=$TOP_EXECUTABLE takeover=$TOP_TAKEOVER defaultAction=$TOP_DEFAULT_ACTION"
    fi
    FAILED=$((FAILED + 1))
  else
    if $VERBOSE; then
      echo "OK ($VISIBLE_ROWS rows, top: '$TOP_TITLE', activation: '$TOP_ACTIVATION', executable: $TOP_EXECUTABLE)"
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