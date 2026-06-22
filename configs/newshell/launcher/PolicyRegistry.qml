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

    function registerPresentation(id, applyFn) {
        JsRegistry.presentation.register(id, {
            name: id,
            phase: "presentation",
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

    function registerBaseNameAliases() {
        var registries = [JsRegistry.evidence, JsRegistry.inherit, JsRegistry.boost, JsRegistry.childVisible, JsRegistry.childBypass, JsRegistry.presentation, JsRegistry.tokenFlow, JsRegistry.takeoverRequest, JsRegistry.takeoverAccept, JsRegistry.expand, JsRegistry.retainParent, JsRegistry.defaultAction, JsRegistry.riskGate];
        var aliasMap = {};
        for (var ri = 0; ri < registries.length; ri += 1) {
            var reg = registries[ri];
            var names = reg.list();
            for (var ni = 0; ni < names.length; ni += 1) {
                var name = names[ni];
                var colonIdx = name.indexOf(":");
                if (colonIdx > 0) {
                    var baseName = name.slice(0, colonIdx);
                    if (reg.get(baseName))
                        continue;
                    reg.register(baseName, reg.get(name));
                    aliasMap[baseName] = name;
                }
            }
        }
        if (Object.keys(aliasMap).length > 0)
            console.log("PolicyRegistry: registered base-name aliases", JSON.stringify(aliasMap));
        return aliasMap;
    }
}
