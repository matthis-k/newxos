pragma Singleton
import QtQml
import Quickshell

Singleton {
    function normalize(spec) {
        if (typeof spec === "string") return normalizeLegacy(spec);
        if (Array.isArray(spec)) return normalizeTuple(spec);
        if (typeof spec === "object" && spec !== null) return normalizeObject(spec);
        return { name: String(spec), legacyName: String(spec), baseName: String(spec), kind: "unknown", args: {}, priority: 0, source: "unknown" };
    }

    function normalizeLegacy(str) {
        var colonIdx = str.indexOf(":");
        var baseName = colonIdx >= 0 ? str.slice(0, colonIdx) : str;
        var argStr = colonIdx >= 0 ? str.slice(colonIdx + 1) : "";

        if (argStr) {
            console.warn("PolicySpec: legacy colon-encoded policy spec is deprecated: '" + str + "'. Use array spec like ['" + baseName + "', { ... }] instead.");
        }

        var kind = classifyBase(baseName);

        return {
            name: str,
            legacyName: str,
            baseName: baseName,
            kind: kind,
            args: {},
            priority: 0,
            source: "legacy"
        };
    }

    function normalizeTuple(arr) {
        if (arr.length < 1) return { name: "", legacyName: "", baseName: "", kind: "unknown", args: {}, priority: 0, source: "tuple" };
        var baseName = String(arr[0]);
        var args = (arr.length >= 2 && typeof arr[1] === "object" && arr[1] !== null && !Array.isArray(arr[1]))
            ? shallowClone(arr[1]) : {};
        var priority = arr.length >= 3 ? Number(arr[2]) || 0 : 0;
        var strArgs = JSON.stringify(args);
        var name = strArgs !== "{}" ? baseName + ":" + strArgs : baseName;
        var kind = classifyBase(baseName);

        return {
            name: name,
            legacyName: baseName,
            baseName: baseName,
            kind: kind,
            args: args,
            priority: priority,
            source: "tuple"
        };
    }

    function normalizeObject(obj) {
        var oName = String(obj.name || obj.baseName || "");
        var baseName = oName;
        var args = obj.args ? shallowClone(obj.args) : {};
        var priority = obj.priority !== undefined ? Number(obj.priority) : 0;
        var kind = obj.kind || classifyBase(baseName);
        var source = obj.source || "object";

        return {
            name: oName,
            legacyName: obj.legacyName || oName,
            baseName: baseName,
            kind: kind,
            args: args,
            priority: priority,
            source: source
        };
    }

    function classifyBase(baseName) {
        switch (baseName) {
        case "field-match": return "evidence";
        case "switch-action": return "evidence";
        case "semantic": return "evidence";
        case "token-claim": return "evidence";
        case "usage": return "evidence";
        case "recency": return "evidence";
        case "path-evidence": return "inherit";
        case "descendant-boost": return "boost";
        case "visible-flag": return "childVisible";
        case "own-score-beats-parent": return "childBypass";
        case "score-dominates": return "childBypass";
        case "own-score-min": return "childBypass";
        case "above-min-score": return "childBypass";
        case "own-score-dominates": return "childBypass";
        case "has-evidence": return "childBypass";
        case "candidate-or-visible": return "childBypass";
        case "score-beats-parent": return "childBypass";
        case "has-base-evidence": return "childBypass";
        case "switch-aliases": return "boost";
        case "pass-all":
        case "consume-own-pass-rest":
        case "claim-context-pass-all":
        case "consume-namespace-pass-rest":
        case "consume-action-token":
        case "consume-switch-pass-rest":
        case "consume-path-segment":
            return "tokenFlow";
        case "explicit-child-token":
        case "child-own-match-parent-no-own-match":
        case "child-covers-passed-tokens":
        case "own-score-dominates-takeover":
        case "exact-action-token-takeover":
            return "takeoverRequest";
        case "accept-all-claims":
        case "accept-explicit-claims":
        case "accept-dominated-claims":
            return "takeoverAccept";
        case "expand-when":
        case "expand-on-own-match":
        case "expand-on-trailing-space":
        case "expand-on-explicit-parent-token":
        case "expand-on-child-match":
        case "expand-on-own-match-or-trailing-space":
        case "expand-all":
        case "expand-none":
            return "expand";
        case "retain-parent-when":
        case "retain-always":
        case "retain-never":
            return "retainParent";
        case "default-action-owner":
        case "default-action-expand":
            return "defaultAction";
        case "risk-gate":
        case "risk-gate-confirm":
        case "risk-gate-block":
            return "riskGate";
        default: return "custom";
        }
    }

    function resolvePreset(spec) {
        if (typeof spec === "string") {
            if (spec.indexOf(":") > 0) {
                var colonIdx = spec.indexOf(":");
                var base = spec.slice(0, colonIdx);
                var argStr = spec.slice(colonIdx + 1);
                return { name: base, args: tryParseNumber(argStr) !== argStr ? {} : { value: tryParseNumber(argStr) }, source: "legacy" };
            }
            return { name: spec, args: {}, source: "string" };
        }
        if (Array.isArray(spec)) {
            var name = String(spec[0]);
            var args = (spec.length >= 2 && typeof spec[1] === "object" && spec[1] !== null) ? shallowClone(spec[1]) : {};
            return { name: name, args: args, source: "tuple" };
        }
        if (typeof spec === "object" && spec !== null) {
            return { name: String(spec.name || ""), args: spec.args ? shallowClone(spec.args) : {}, source: "object" };
        }
        return { name: String(spec), args: {}, source: "unknown" };
    }

    function tryParseNumber(val) {
        if (typeof val === "number") return val;
        var n = Number(val);
        return isNaN(n) ? val : n;
    }

    function shallowClone(obj) {
        var out = {};
        for (var k in obj) {
            if (Object.prototype.hasOwnProperty.call(obj, k))
                out[k] = obj[k];
        }
        return out;
    }
}
