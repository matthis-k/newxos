pragma Singleton
import QtQml
import Quickshell
import "PolicySpec.qml"

Singleton {
    readonly property var defaultModes: ({
        evidence: "accumulate",
        boost: "best-wins",
        childVisible: "all-and",
        childBypass: "all-or",
        presentation: "first-wins"
    })

    function lookupPolicy(registry, spec) {
        if (!registry || !spec) return null;
        return spec.name ? registry.get(spec.name) : null;
    }

    function run(names, call, modeOrPhase, tracePerPolicy) {
        var mode = defaultModes[modeOrPhase] || modeOrPhase;
        if (!mode)
            return { value: null, priority: 0 };

        var results = [];
        for (var i = 0; i < names.length; i += 1) {
            var spec = PolicySpec.normalize(names[i]);
            if (!spec)
                continue;
            var raw = call(spec.name, spec);
            if (raw === null || raw === undefined)
                continue;
            var r = normalize(raw);

            // Trace each policy at the real execution site
            if (typeof tracePerPolicy === "function") {
                var effect = "no-op";
                var modeEffect = "";
                if (mode === "first-wins")
                    modeEffect = "selected";
                else if (mode === "best-wins")
                    modeEffect = "considered";
                else if (mode === "accumulate")
                    modeEffect = "accumulated";
                else if (mode === "all-and" || mode === "all-or")
                    modeEffect = "evaluated";
                if (r.value !== null && r.value !== undefined) {
                    if (mode === "first-wins" && results.length === 0)
                        effect = "selected";
                    else if (mode !== "first-wins")
                        effect = modeEffect;
                    else
                        effect = "ignored";
                }
                tracePerPolicy({
                    name: spec.name,
                    priority: spec.priority || 0,
                    enabled: true,
                    args: spec.args || null,
                    returned: { value: r.value, reasons: r.reasons || [], priority: r.priority || 0 },
                    effect: effect
                });
            }

            results.push(r);
            if (mode === "first-wins") {
                // Trace remaining not-evaluated policies
                if (typeof tracePerPolicy === "function") {
                    for (var j = i + 1; j < names.length; j += 1) {
                        var remainingSpec = PolicySpec.normalize(names[j]);
                        if (!remainingSpec)
                            continue;
                        tracePerPolicy({
                            name: remainingSpec.name,
                            priority: remainingSpec.priority || 0,
                            enabled: true,
                            args: remainingSpec.args || null,
                            returned: null,
                            effect: "not-evaluated",
                            reasons: [{
                                code: "first_wins_short_circuit",
                                text: "Policy was not evaluated because an earlier first-wins policy already selected a result."
                            }]
                        });
                    }
                }
                break;
            }
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
            return { value: raw, priority: 0, reasons: [] };
        if (raw.hasOwnProperty("value"))
            return {
                value: raw.value,
                priority: raw.priority || 0,
                reasons: raw.reasons || []
            };
        return {
            value: raw,
            priority: 0,
            reasons: raw.reasons || []
        };
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
