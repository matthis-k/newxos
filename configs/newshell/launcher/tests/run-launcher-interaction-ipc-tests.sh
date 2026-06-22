#!/usr/bin/env bash
# Semantic launcher interaction IPC test suite.
# Tests interactJson/state IPC methods — no visible launcher required.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../../../.."

IPC=(newshell ipc call launcher)
QUERY_IPC=(newshell ipc call query)
FAILED=0
PASSED=0
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose|-v) VERBOSE=true; shift ;;
    *) echo "Usage: $0 [--verbose|-v]" >&2; exit 2 ;;
  esac
done

call_interact()   { "${IPC[@]}" interactJson "$1"; }
state()           { "${IPC[@]}" state; }
fail()            { echo "FAIL: $1 - $2"; FAILED=$((FAILED + 1)); }
pass()            { PASSED=$((PASSED + 1)); $VERBOSE && echo "OK: $1"; }

assert_jq_data() {
  local name="$1" data="$2" expr="$3" msg="$4"
  if echo "$data" | jq -e "$expr" >/dev/null 2>&1; then
    pass "$name"
  else
    $VERBOSE && echo "$data" | jq '.' 2>/dev/null || true
    fail "$name" "$msg"
  fi
}

wait_for_query() {
  local expected="$1" tries="${2:-20}"
  for _ in $(seq 1 "$tries"); do
    local s
    s=$(state || true)
    if echo "$s" | jq -e --arg q "$expected" '.query == $q or .inputText == $q' >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.05
  done
  return 1
}

echo "=== Launcher Interaction IPC Test Suite ==="
echo ""

# ============================================================
# Envelope validation
# ============================================================
echo "--- Envelope validation ---"

data=$(call_interact '{"action":"state"}')
assert_jq_data "state-envelope" "$data" \
  '.version == 1 and .ok == true and .after.type == "launcherInteractionState"' \
  "state action should return state envelope"

data=$(call_interact '{"action":"open"}')
assert_jq_data "open" "$data" \
  '.ok == true' \
  "open should return ok"

data=$(call_interact '{"action":"setQuery","query":"wifi"}')
assert_jq_data "set-query-response" "$data" \
  '.ok == true' \
  "setQuery should return ok"
wait_for_query "wifi" || fail "set-query-wait" "state query did not become wifi"

data=$(call_interact '{"action":"typeText","text":" on"}')
assert_jq_data "type-text" "$data" \
  '.ok == true' \
  "typeText should return ok"
wait_for_query "wifi on" || fail "type-text-wait" "state query did not become 'wifi on'"

data=$(call_interact '{"action":"backspace","count":3}')
assert_jq_data "backspace" "$data" \
  '.ok == true' \
  "backspace should return ok"
wait_for_query "wifi" || fail "backspace-wait" "state query did not revert to 'wifi'"

data=$(call_interact '{"action":"moveSelection","delta":1}')
assert_jq_data "move-selection" "$data" \
  '.ok == true and (.after.selectedIndex | type == "number")' \
  "moveSelection should return valid state"

data=$(call_interact '{"action":"expandSelected"}')
assert_jq_data "expand-selected" "$data" \
  '.ok == true' \
  "expandSelected should not crash"

data=$(call_interact '{"action":"collapseSelected"}')
assert_jq_data "collapse-selected" "$data" \
  '.ok == true' \
  "collapseSelected should not crash"

data=$(call_interact '{"action":"clearQuery"}')
assert_jq_data "clear-query" "$data" \
  '.ok == true' \
  "clearQuery should return ok"
wait_for_query "" || true

echo ""
echo "--- Risk/confirmation safety ---"

data=$(call_interact '{"action":"setQuery","query":"shutdown"}')
assert_jq_data "risky-query" "$data" \
  '.ok == true' \
  "shutdown query should be accepted"
wait_for_query "shutdown" || true

data=$(call_interact '{"action":"activateSelected"}')
assert_jq_data "risky-activation-no-bypass" "$data" \
  '.ok == true and (.after.visible == true or .after.closing == false)' \
  "risky activation must not bypass confirmation and close launcher unexpectedly"

echo ""
echo "--- Error handling ---"

data=$(call_interact '{"action":"doesNotExist"}')
assert_jq_data "unknown-action" "$data" \
  '.ok == false and .error.code == "unknown_action"' \
  "unknown action should return structured error"

data=$(call_interact 'not-json-at-all')
assert_jq_data "invalid-json" "$data" \
  '.ok == false and .error.code == "invalid_json"' \
  "invalid JSON should return structured invalid_json error"

echo ""
echo "--- Two-argument interact ---"

data=$("${IPC[@]}" interact setQuery '{"query":"network"}')
assert_jq_data "interact-two-arg-set-query" "$data" \
  '.ok == true' \
  "two-argument interact should accept a JSON payload"
wait_for_query "network" || fail "interact-two-arg-wait" "state query did not become network"

echo ""
echo "--- Visual state ---"

data=$(call_interact '{"action":"state","visual":true}')
assert_jq_data "state-with-visual" "$data" \
  '.ok == true and (.after.visual.items | type == "array")' \
  "state visual=true should include visual metrics"

echo ""
echo "--- query visualDebug compatibility ---"

data=$("${QUERY_IPC[@]}" visualDebug on)
assert_jq_data "query-visual-debug-contract-on" "$data" \
  '.version == 1 and .type == "visualState" and .current != null' \
  "query visualDebug on should preserve visualState response"

data=$("${QUERY_IPC[@]}" visualDebug off)
assert_jq_data "query-visual-debug-contract-off" "$data" \
  '.version == 1 and .type == "visualState" and .current != null' \
  "query visualDebug off should preserve visualState response"

echo ""
echo "--- Activation structured result ---"

data=$(call_interact '{"action":"activateSelected"}')
assert_jq_data "activate-structured-result" "$data" \
  '.ok == true and (.result.mode | type == "string") and (.result.result != null or .result.close == false or .result.closeRequested == false)' \
  "activateSelected should return structured semantic result"

echo ""
echo "--- Close ---"

data=$(call_interact '{"action":"close"}')
assert_jq_data "close" "$data" \
  '.ok == true' \
  "close should return ok"

echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
[[ $FAILED -eq 0 ]]
