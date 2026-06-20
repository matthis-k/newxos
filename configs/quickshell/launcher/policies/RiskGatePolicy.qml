import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    // Returns mode/reason but does NOT override allowed for confirm/prefix modes.
    // ActivationGate owns the allowed decision — this policy only adds context.
    // Monotonic rule: may only tighten (allowed=false), never loosen (allowed=true).
    function riskGateApply(node, ctx, args) {
        if (!args) return null;
        var mode = args.activation || "normal";
        var level = args.level || "none";
        var upstreamAllowed = args.allowed !== undefined ? args.allowed : true;

        switch (mode) {
        case "blocked":
            return { allowed: false, reason: "risk-gate: execution blocked by policy", mode: "blocked" };
        case "confirm":
            // Advisory only — ActivationGate sets allowed based on confirmationSatisfied.
            // If upstream already blocked, respect that (monotonic).
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
            return {
                allowed: upstreamAllowed === false ? false : undefined,
                reason: "risk-gate: explicit prefix required",
                mode: "explicit-prefix"
            };
        default:
            return { allowed: true, reason: "risk-gate: normal activation", mode: "normal" };
        }
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerRiskGate("risk-gate", riskGateApply);
        Launcher.PolicyRegistry.registerRiskGate("risk-gate-confirm", function(node, ctx, args) {
            return {
                allowed: args && args.allowed === false ? false : undefined,
                mode: "confirm",
                reason: "risk-gate: confirm required"
            };
        });
        Launcher.PolicyRegistry.registerRiskGate("risk-gate-block", function(node, ctx, args) {
            return { allowed: false, mode: "blocked", reason: "risk-gate: blocked" };
        });
    }
}
