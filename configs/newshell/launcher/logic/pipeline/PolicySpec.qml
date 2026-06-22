pragma Singleton
import QtQml
import Quickshell

Singleton {
    function normalize(spec) {
        if (!spec)
            return null;

        if (typeof spec === "string")
            return normalizeShorthand(spec);

        if (Array.isArray(spec))
            return normalizeArray(spec);

        if (typeof spec === "object")
            return normalizeObject(spec);

        return null;
    }

    function normalizeShorthand(name) {
        return {
            name: name,
            kind: guessKind(name),
            args: {},
            priority: 0,
            source: "global"
        };
    }

    function normalizeArray(arr) {
        var name = String(arr[0] || "");
        if (!name)
            return null;

        var args = {};
        var priority = 0;

        if (arr.length >= 2 && typeof arr[1] === "object" && !Array.isArray(arr[1]))
            args = arr[1];

        if (arr.length >= 3 && typeof arr[2] === "number")
            priority = arr[2];

        return {
            name: name,
            kind: guessKind(name),
            args: args,
            priority: priority,
            source: "global"
        };
    }

    function normalizeObject(obj) {
        var name = String(obj.name || obj.id || "");
        if (!name)
            return null;

        return {
            name: name,
            kind: obj.kind || guessKind(name),
            args: obj.args || {},
            priority: obj.priority || 0,
            source: obj.source || "global"
        };
    }

    function guessKind(name) {
        if (!name) return "unknown";
        if (name.indexOf("field-match") === 0) return "evidence";
        if (name.indexOf("token") === 0) return "tokenFlow";
        if (name.indexOf("score") === 0) return "scoring";
        if (name.indexOf("switch") === 0) return "evidence";
        if (name === "path-evidence") return "inherit";
        if (name === "descendant-boost") return "boost";
        if (name.indexOf("visible") === 0) return "childVisible";
        if (name.indexOf("own-score") === 0) return "childBypass";
        if (name.indexOf("score") === 0) return "childBypass";
        if (name.indexOf("presentation") === 0) return "presentation";
        if (name.indexOf("preset") === 0) return "presentation";
        if (name.indexOf("usage") === 0) return "evidence";
        if (name.indexOf("recency") === 0) return "evidence";
        if (name.indexOf("semantic") === 0) return "evidence";
        if (name.indexOf("above-min") === 0) return "childVisible";
        if (name.indexOf("own-score-min") === 0) return "childVisible";
        if (name.indexOf("candidate") === 0) return "childVisible";
        if (name.indexOf("has-evidence") === 0) return "childVisible";
        if (name.indexOf("has-own") === 0) return "childVisible";
        return "unknown";
    }

    function normalizeProfile(profile) {
        if (!profile) return {};
        var out = {};
        for (var key in profile) {
            var specs = profile[key];
            if (!Array.isArray(specs)) {
                out[key] = specs;
                continue;
            }
            out[key] = specs.map(normalize).filter(function(s) { return !!s; });
        }
        return out;
    }

    function compactLegacyName(name) {
        if (!name) return "";
        var s = String(name);
        var colonIdx = s.indexOf(":");
        if (colonIdx > 0)
            return s.slice(0, colonIdx);
        return s;
    }
}
