import QtQml
import qs.services
import "../" as Launcher
import "../logic/"

QtObject {
    readonly property var tracer: Logger.scope("policy.riskGate", { category: "policy" })
    readonly property var prof: Profiler.scope("policy.riskGate", { category: "policy" })

    function riskGateApply(node, ctx, runtime, specArgs) {
        if (!runtime) return null;
        var mode = runtime.activation || "normal";
        var level = runtime.level || "none";
        tracer.trace("riskGateApply", function() { return { nodeId: node?.id, mode: mode, level: level }; });
        var level = runtime.level || "none";
        var upstreamAllowed = runtime.allowed !== undefined ? runtime.allowed : true;

        var blockLevels = specArgs && specArgs.blockLevels || [];
        if (blockLevels.length > 0 && blockLevels.indexOf(level) >= 0) {
            return { allowed: false, mode: "blocked", reason: "risk-gate: blocked risk level " + level };
        }

        switch (mode) {
        case "blocked":
            return { allowed: false, reason: "risk-gate: execution blocked by policy", mode: "blocked" };
        case "confirm":
            return {
                allowed: upstreamAllowed === false ? false : undefined,
                reason: "risk-gate: confirmation required",
                mode: "confirm"
            };
        case "confirm-and-explicit-prefix":
            return {
                allowed: upstreamAllowed === false ? false : undefined,
                reason: "risk-gate: confirmation and explicit prefix required",
                mode: "confirm-and-explicit-prefix"
            };
        case "explicit-prefix":
        case "explicit-prefix-only":
            return {
                allowed: upstreamAllowed === false ? false : undefined,
                reason: "risk-gate: explicit prefix required",
                mode: mode
            };
        default:
            return { allowed: undefined, reason: "risk-gate: normal activation", mode: "normal" };
        }
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerRiskGate("risk-gate", riskGateApply);
        Launcher.PolicyRegistry.registerRiskGate("risk-gate-confirm", function(node, ctx, runtime, specArgs) {
            return {
                allowed: runtime && runtime.allowed === false ? false : undefined,
                mode: "confirm",
                reason: "risk-gate: confirm required"
            };
        });
        Launcher.PolicyRegistry.registerRiskGate("risk-gate-block", function(node, ctx, runtime, specArgs) {
            return { allowed: false, mode: "blocked", reason: "risk-gate: blocked" };
        });
    }
}
