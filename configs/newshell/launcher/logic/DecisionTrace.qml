pragma Singleton
import QtQml
import Quickshell
import qs.services

Singleton {
    readonly property var prof: Profiler.scope("launcher.decisionTrace", { category: "launcher" })
    readonly property var tracer: Logger.scope("launcher.decisionTrace", { category: "launcher" })

    function initPolicyTrace(ev, ctx) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (tracer.traceOn) tracer.trace("initPolicyTrace", function() { return { nodeId: nid }; });
        if (!ctx._policyTrace[nid]) ctx._policyTrace[nid] = {};
    }

    function policy(ev, ctx, kind, name, returned, effect, reasons) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (tracer.traceOn) tracer.trace("policy", function() { return { nodeId: nid, kind: kind, name: name, effect: effect }; });
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

    function placement(ev, ctx, decision) {
        if (!ev || !ev.node || !ev.node.id || !ctx._decisionTrace) return;
        var nid = ev.node.id;
        tracer.trace("placement", function() { return { nodeId: nid, mode: decision.mode, placement: decision.placement || decision.mode }; });
        var expandFinal = ctx._policyTrace && ctx._policyTrace[nid] && ctx._policyTrace[nid].expand && ctx._policyTrace[nid].expand.final;
        var retainFinal = ctx._policyTrace && ctx._policyTrace[nid] && ctx._policyTrace[nid].retain && ctx._policyTrace[nid].retain.final;
        var takeoverFinal = ctx._policyTrace && ctx._policyTrace[nid] && ctx._policyTrace[nid].takeover && ctx._policyTrace[nid].takeover.final;
        ctx._decisionTrace[nid] = {
            nodeId: nid,
            visibility: { value: { visible: ev.visible }, reasons: [{ code: "visibility", text: "visible=" + ev.visible + " ownVisible=" + ev.ownVisible }] },
            placement: { value: decision.placement || decision.mode || "unknown", reasons: [{ code: "placement", text: "mode=" + (decision.mode || "normal") + " showParent=" + (decision.showParent !== false) + " placement=" + (decision.placement || decision.mode || "unknown") }] },
            flattening: { value: { flatten: decision.mode === "flatten-children" || decision.mode === "flatten-all-children", mode: decision.mode || "normal" }, reasons: [{ code: "flattening", text: "mode=" + (decision.mode || "normal") }] },
            breadcrumbs: null,
            defaultAction: null,
            childVisibility: null,
            _expand: expandFinal || null,
            _retain: retainFinal || null,
            _takeover: takeoverFinal || null
        };
        final(ev, ctx, "placement", { placement: decision.placement || decision.mode || "unknown", mode: decision.mode || "normal", showParent: decision.showParent !== false }, [{ code: "placement_decided", text: "final placement=" + (decision.placement || decision.mode || "unknown") + " mode=" + (decision.mode || "normal") }]);
    }

    function final(ev, ctx, kind, value, reasons) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (tracer.traceOn) tracer.trace("final", function() { return { nodeId: nid, kind: kind }; });
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
