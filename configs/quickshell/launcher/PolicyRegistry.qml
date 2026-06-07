pragma Singleton
import QtQml
import Quickshell
import "logic/CompositeSearchPolicyRegistry.js" as JsRegistry

Singleton {
    function registerEvidence(id, group, matchFn) {
        JsRegistry.evidence.register(id, {
            name: id,
            phase: "evidence",
            group: group || "own",
            match: matchFn
        });
    }

    function registerInherit(id, applyFn) {
        JsRegistry.inherit.register(id, {
            name: id,
            phase: "inherit",
            apply: applyFn
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

    function registerChildBypass(id, applyFn) {
        JsRegistry.childBypass.register(id, {
            name: id,
            phase: "child-bypass",
            apply: applyFn
        });
    }
}
