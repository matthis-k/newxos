pragma Singleton
import QtQml
import Quickshell

Singleton {
    readonly property var defaultModes: ({
        evidence: "accumulate",
        inherit: "accumulate",
        boost: "best-wins",
        childVisible: "all-and",
        childBypass: "all-or",
        presentation: "first-wins"
    })

    function run(names, call, modeOrPhase) {
        var mode = defaultModes[modeOrPhase] || modeOrPhase;
        if (!mode)
            return { value: null, priority: 0 };

        var results = [];
        for (var i = 0; i < names.length; i += 1) {
            var raw = call(names[i]);
            if (raw === null || raw === undefined)
                continue;
            var r = normalize(raw);
            results.push(r);
            if (mode === "first-wins")
                break;
            if (mode === "all-and" && !r.value)
                return { value: false, priority: 0 };
            if (mode === "all-or" && r.value)
                return { value: true, priority: 0 };
        }
        return combine(results, mode);
    }

    function normalize(raw) {
        if (raw === null || raw === undefined)
            return null;
        if (typeof raw !== "object" || Array.isArray(raw))
            return { value: raw, priority: 0 };
        if (raw.hasOwnProperty("value"))
            return { value: raw.value, priority: raw.priority || 0 };
        return { value: raw, priority: 0 };
    }

    function combine(results, mode) {
        if (!results.length) {
            switch (mode) {
            case "all-and":  return { value: true };
            case "all-or":   return { value: false };
            case "accumulate": return { value: [] };
            default:         return { value: null };
            }
        }
        switch (mode) {
        case "accumulate": {
            var acc = [];
            for (var i = 0; i < results.length; i += 1) {
                var v = results[i].value;
                if (Array.isArray(v))
                    acc = acc.concat(v);
                else
                    acc.push(v);
            }
            return { value: acc };
        }
        case "all-and":
            return { value: results.every(function(r) { return r.value; }) };
        case "all-or":
            return { value: results.some(function(r) { return r.value; }) };
        case "first-wins":
            return results[0];
        case "best-wins": {
            var best = results[0];
            for (var i = 1; i < results.length; i += 1) {
                var ri = results[i];
                if (ri.priority > best.priority || (ri.priority === best.priority && ri.value > best.value))
                    best = ri;
            }
            return best;
        }
        default:
            return results[0] || { value: null, priority: 0 };
        }
    }
}
