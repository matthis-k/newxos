// PolicyChain internal tests — loadable via newshell-runtime or dev shell
// Verifies:
// 1. Policy priority from spec affects normalization
// 2. Trace preservation: evaluated entries not overwritten
// 3. DecisionTrace.policy() preserves nonzero priority
//
// Usage: newshell ipc call debugPolicies '{"check":"policy-chain-invariants"}'

import QtQml
import Quickshell
import qs.services
import "../logic/PolicyChain.qml"
import "../logic/DecisionTrace.qml"
import "../logic/DecisionDecider.qml"

QtObject {
    readonly property var tracer: Logger.scope("test.policyChain", { category: "test" })

    function result(ok, label, detail) {
        return { ok: ok, label: label, detail: detail || "" };
    }

    function runAll() {
        var results = [];
        results.push(testPriorityFromSpec());
        results.push(testPriorityFromResult());
        results.push(testTieBreakFirst());
        results.push(testDeciderHighestPriority());
        results.push(testDeciderCustom());
        results.push(testDecisionTracePriority());
        results.push(testNormalizeReasons());
        results.push(testNormalizeDecisionField());
        return { name: "PolicyChain", results: results };
    }

    function testPriorityFromSpec() {
        // [["policy-a", {}, 10], ["policy-b", {}, 80]] with highest-priority/best-wins
        // must select "policy-b" even when policy result has no priority
        var result = PolicyChain.run([
            ["policy-a", {}, 10],
            ["policy-b", {}, 80]
        ], function(name, spec) {
            if (name === "policy-a") return { decision: { value: 1 } };
            if (name === "policy-b") return { decision: { value: 2 } };
            return null;
        }, "best-wins");

        var ok = result && result.policy === "policy-b" && result.priority === 80;
        return result(ok, "priority-from-spec", ok ? "Selected policy-b (priority 80)" : "Selected " + (result ? result.policy : "none") + " (priority " + (result ? result.priority : 0) + ")");
    }

    function testPriorityFromResult() {
        // Priority from result overrides spec priority
        var result = PolicyChain.run([
            ["policy-a", {}, 10]
        ], function(name, spec) {
            return { decision: { value: 1 }, priority: 50 };
        }, "best-wins");

        var ok = result && result.priority === 50;
        return result(ok, "priority-from-result", ok ? "Priority 50 from result" : "Priority " + (result ? result.priority : 0));
    }

    function testTieBreakFirst() {
        // Same priority preserves profile order (first wins)
        var result = PolicyChain.run([
            ["policy-a", {}, 50],
            ["policy-b", {}, 50]
        ], function(name, spec) {
            if (name === "policy-a") return { decision: { value: 1 } };
            if (name === "policy-b") return { decision: { value: 2 } };
            return null;
        }, "first-wins");

        var ok = result && result.policy === "policy-a";
        return result(ok, "tie-break-first-wins", ok ? "policy-a selected (first in profile)" : "policy-b selected");
    }

    function testDeciderHighestPriority() {
        var votes = [
            { decision: { value: 1 }, priority: 10, policy: "policy-a", reasons: [] },
            { decision: { value: 2 }, priority: 80, policy: "policy-b", reasons: [] },
            { decision: { value: 3 }, priority: 50, policy: "policy-c", reasons: [] }
        ];
        var decider = DecisionDecider.reduce("test-kind", votes, { mode: "highest-priority" });
        var ok = decider && decider.selectedPolicy === "policy-b" && decider.priority === 80;
        return result(ok, "decider-highest-priority", ok ? "policy-b selected (priority 80)" : "Selected " + (decider ? decider.selectedPolicy : "none"));
    }

    function testDeciderCustom() {
        var votes = [
            { decision: { value: "a" }, priority: 10, policy: "policy-a", reasons: [] },
            { decision: { value: "b" }, priority: 80, policy: "policy-b", reasons: [] }
        ];
        var decider = DecisionDecider.reduce("test-kind", votes, {
            mode: "custom",
            custom: function(v, ctx) {
                for (var i = 0; i < v.length; i += 1) {
                    if (v[i].policy === "policy-a") return v[i];
                }
                return null;
            }
        });
        var ok = decider && decider.selectedPolicy === "policy-a";
        return result(ok, "decider-custom", ok ? "policy-a selected via custom reducer" : "Selected " + (decider ? decider.selectedPolicy : "none"));
    }

    function testDecisionTracePriority() {
        // Verify DecisionTrace.policy() preserves nonzero priority from vote object
        var ev = { node: { id: "test-node" } };
        var ctx = { _policyTrace: {} };
        var vote = { decision: { value: true }, priority: 75, policy: "test-policy", reasons: [{ code: "test", text: "test" }] };
        DecisionTrace.policy(ev, ctx, "expand", vote, vote.decision, "selected", [{ code: "test", text: "test" }]);

        var trace = ctx._policyTrace["test-node"];
        var ok = trace && trace.expand && trace.expand.evaluated.length === 1 && trace.expand.evaluated[0].priority === 75;
        var actual = trace && trace.expand ? trace.expand.evaluated[0].priority : 0;
        return result(ok, "trace-priority", ok ? "Priority 75 preserved in trace" : "Got priority " + actual);
    }

    function testNormalizeReasons() {
        var r = PolicyChain.normalizePolicyResult({
            decision: { value: true },
            reasons: [{ code: "test", text: "test reason" }]
        }, null);
        var ok = r && r.reasons && r.reasons.length === 1 && r.reasons[0].code === "test";
        return result(ok, "normalize-reasons-array", ok ? "Reasons array preserved" : "Got " + (r ? JSON.stringify(r.reasons) : "null"));
    }

    function testNormalizeDecisionField() {
        var r = PolicyChain.normalizePolicyResult({
            decision: { expand: true, maxChildren: 8 }
        }, { name: "expand-on-trailing-space", kind: "expand" });
        var ok = r && r.decision && r.decision.expand === true && r.decision.maxChildren === 8 && r.policy === "expand-on-trailing-space";
        return result(ok, "normalize-decision-field", ok ? "Decision field extracted, policy attached" : "Got " + (r ? JSON.stringify(r) : "null"));
    }
}
