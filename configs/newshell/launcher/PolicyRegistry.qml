pragma Singleton
import QtQml
import Quickshell
import qs.services
import "logic/CompositeSearchPolicyRegistry.js" as JsRegistry

Singleton {
    readonly property var tracer: Logger.scope("launcher.policyRegistry", { category: "launcher" })
    readonly property var prof: Profiler.scope("launcher.policyRegistry", { category: "launcher" })
    function registerEvidence(id, group, matchFn) {
        tracer.trace("registerEvidence", function() { return { id: id, group: group }; });
        JsRegistry.evidence.register(id, {
            name: id,
            phase: "evidence",
            group: group || "own",
            match: matchFn
        });
    }

    function registerBoost(id, applyFn) {
        JsRegistry.boost.register(id, {
            name: id,
            phase: "boost",
            apply: applyFn
        });
    }

    function registerChildVisible(id, applyFn) {
        JsRegistry.childVisible.register(id, {
            name: id,
            phase: "child-visible",
            apply: applyFn
        });
    }

    function registerTokenFlow(id, applyFn) {
        JsRegistry.tokenFlow.register(id, {
            name: id,
            phase: "tokenFlow",
            apply: applyFn
        });
    }

    function registerTakeoverRequest(id, applyFn) {
        JsRegistry.takeoverRequest.register(id, {
            name: id,
            phase: "takeoverRequest",
            apply: applyFn
        });
    }

    function registerTakeoverAccept(id, applyFn) {
        JsRegistry.takeoverAccept.register(id, {
            name: id,
            phase: "takeoverAccept",
            apply: applyFn
        });
    }

    function registerExpand(id, applyFn) {
        JsRegistry.expand.register(id, {
            name: id,
            phase: "expand",
            apply: applyFn
        });
    }

    function registerRetainParent(id, applyFn) {
        JsRegistry.retainParent.register(id, {
            name: id,
            phase: "retainParent",
            apply: applyFn
        });
    }

    function registerDefaultAction(id, applyFn) {
        JsRegistry.defaultAction.register(id, {
            name: id,
            phase: "defaultAction",
            apply: applyFn
        });
    }

    function registerRiskGate(id, applyFn) {
        JsRegistry.riskGate.register(id, {
            name: id,
            phase: "riskGate",
            apply: applyFn
        });
    }

    function registerNesting(id, applyFn) {
        JsRegistry.nesting.register(id, {
            name: id,
            phase: "nesting",
            apply: applyFn
        });
    }

}
