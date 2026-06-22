pragma Singleton
import QtQml
import Quickshell
import "PolicyChain.qml"
import "CompositeSearchPolicyRegistry.js" as JsRegistry

Singleton {
    function riskLevelForNode(node) {
        if (!node) return "none";
        if (node.risk && node.risk.level) return node.risk.level;
        if (node.dangerous) return "state-change";
        return "none";
    }

    function activationModeForNode(node) {
        if (!node) return "normal";
        if (node.risk && node.risk.activation) return node.risk.activation;
        if (node.dangerous) {
            var label = String(node.label || "").toLowerCase();
            if (label.indexOf("logout") >= 0 || label.indexOf("shutdown") >= 0 || label.indexOf("reboot") >= 0 || label.indexOf("hibernate") >= 0)
                return "confirm-and-explicit-prefix";
            return "confirm";
        }
        return "normal";
    }

    // Checks whether the user query includes an explicit directive prefix (":").
    // Prefers structured directive/route context over raw string scanning.
    function _hasExplicitPrefix(queryText, ctx) {
        if (ctx) {
            // Structured directive context (from search pipeline via ctx.directive)
            if (ctx.directive && ctx.directive.active)
                return ctx.directive.prefix === ":";
            if (ctx.route && ctx.route.combine === "exclusive") {
                var eps = ctx.route.endpoints || [];
                return eps.length > 0 && eps[0].prefix === ":";
            }
            // Controller context fallback (from ActionRegistry via controller.lastDirective)
            if (ctx.lastDirective && ctx.lastDirective.active)
                return ctx.lastDirective.prefix === ":";
        }
        // Raw query fallback (last resort / backward compat)
        return !!(queryText && queryText.length > 1 && queryText.indexOf(":") >= 0);
    }

    function resolveActivation(node, ctx, queryText, confirmationSatisfied) {
        var mode = activationModeForNode(node);
        var level = riskLevelForNode(node);
        var allowed = true;
        var reason = "normal activation";
        var conf = !!confirmationSatisfied;
        var hasPrefix = _hasExplicitPrefix(queryText, ctx);

        switch (mode) {
        case "blocked":
            allowed = false;
            reason = "activation blocked by risk policy";
            break;
        case "confirm":
            allowed = conf;
            reason = conf ? "activation via confirmation" : "activation blocked: confirmation required";
            break;
        case "explicit-prefix":
        case "explicit-prefix-only":
            allowed = hasPrefix;
            reason = hasPrefix ? "activation via explicit prefix" : "activation blocked: explicit prefix required";
            break;
        case "confirm-and-explicit-prefix":
            allowed = conf && hasPrefix;
            reason = allowed
                ? "activation via explicit prefix + confirmation"
                : conf
                    ? "activation blocked: explicit prefix required"
                    : hasPrefix
                        ? "activation blocked: confirmation required"
                        : "activation blocked: explicit prefix required";
            break;
        default:
            allowed = true;
            reason = "normal activation";
        }

        var gateResult = null;
        var riskPolicy = JsRegistry.riskGate.get("risk-gate");
        if (riskPolicy) {
            gateResult = riskPolicy.apply(node, ctx, { activation: mode, level: level, confirmation: conf, allowed: allowed });
            if (gateResult && gateResult.allowed !== undefined) {
                allowed = gateResult.allowed;
                if (gateResult.reason)
                    reason = gateResult.reason;
            }
        }

        return {
            allowed: allowed,
            mode: mode,
            riskLevel: level,
            reason: reason,
            policyReason: gateResult && gateResult.reason ? gateResult.reason : "",
            requiresConfirm: mode === "confirm" || mode === "confirm-and-explicit-prefix",
            requiresExplicitPrefix: mode === "explicit-prefix-only" || mode === "confirm-and-explicit-prefix" || mode === "explicit-prefix"
        };
    }

    function guardActivation(node, action, ctx, queryText, confirmationSatisfied) {
        var resolved = resolveActivation(node, ctx, queryText, confirmationSatisfied);
        if (!resolved.allowed) {
            console.warn("ActivationGate: activation blocked for", node.label || node.id, "reason:", resolved.reason);
            return false;
        }
        return true;
    }

    function canActivate(node, action, ctx, queryText, confirmationSatisfied) {
        return guardActivation(node, action, ctx, queryText, confirmationSatisfied);
    }
}
