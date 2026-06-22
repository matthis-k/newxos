pragma Singleton
import QtQml

QtObject {
    function initPolicyTrace(ev, ctx) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (!ctx._policyTrace[nid]) ctx._policyTrace[nid] = {};
    }

    function policy(ev, ctx, kind, name, returned, effect, reasons) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (!ctx._policyTrace[nid]) ctx._policyTrace[nid] = {};
        if (!ctx._policyTrace[nid][kind]) {
            ctx._policyTrace[nid][kind] = {
                kind: kind,
                evaluated: [],
                aggregate: null,
                final: null
            };
        }
        ctx._policyTrace[nid][kind].evaluated.push({
            name: String(name || kind),
            priority: 0,
            enabled: true,
            returned: returned !== undefined ? returned : null,
            effect: String(effect || "no-op"),
            reasons: (reasons || []).slice()
        });
    }

    function final(ev, ctx, kind, value, reasons) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (!ctx._policyTrace[nid]) ctx._policyTrace[nid] = {};
        if (!ctx._policyTrace[nid][kind]) {
            ctx._policyTrace[nid][kind] = { kind: kind, evaluated: [], aggregate: null, final: null };
        }
        ctx._policyTrace[nid][kind].final = {
            value: value,
            reasons: (reasons || []).slice()
        };
    }
}
