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

        var args = {};
        var kind = classifyBase(baseName);

        if (argStr) {
            args.value = tryParseNumber(argStr);
            args[baseName.replace(/-/g, "_")] = args.value;
            if (baseName === "field-match") args.filterType = argStr;
            if (baseName === "above-min-score") args.threshold = args.value;
            if (baseName === "own-score-min") args.threshold = args.value;
            if (baseName === "score-dominates") args.margin = args.value;
            if (baseName === "own-score-dominates") args.margin = args.value;
        }

        return {
            name: str,
            legacyName: str,
            baseName: baseName,
            kind: kind,
            args: args,
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
        default: return "custom";
        }
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
