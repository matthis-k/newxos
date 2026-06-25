import "../logic/EvaluationProfiles.js" as EvalProfiles

Node {
    id: root
    template: "switch"

    property var onAction: null
    property var offAction: null
    property var toggleAction: null
    property string switchActionId: ""
    property var switchOnAliases: []
    property var switchOffAliases: []
    property var switchToggleAliases: []
    property bool switchOffDangerous: true
    property var childVisible: null

    function switchAction(kind, state, actionFn, dangerous) {
        tracer.trace("switchAction", function() { return { kind: kind, hasFn: typeof actionFn === "function" }; });
        if (typeof actionFn !== "function")
            return null;
        return {
            id: kind,
            actionId: root.switchActionId || root.actionId || root.name || "run",
            title: kind === "on" ? qsTr("On") : kind === "off" ? qsTr("Off") : qsTr("Toggle"),
            state: state,
            execute: actionFn,
            dangerous: !!dangerous
        };
    }

    function ownSwitchActions() {
        tracer.trace("ownSwitchActions", function() { return { nodeId: root.nodeId, hasToggle: !!root.toggleAction, hasOn: !!root.onAction, hasOff: !!root.offAction }; });
        var actions = {};
        var toggle = root.switchAction("toggle", null, root.toggleAction, false);
        var on = root.switchAction("on", true, root.onAction, false);
        var off = root.switchAction("off", false, root.offAction, root.switchOffDangerous);
        if (toggle) actions.toggle = toggle;
        if (on) actions.on = on;
        if (off) actions.off = off;
        return actions;
    }

    function ownChildNodes() {
        var out = [];
        for (var ci = 0; ci < (root.dynamicChildren || []).length; ci += 1)
            out.push(root.ownMaterializeChild(root.dynamicChildren[ci]));
        for (var i = 0; i < root.entries.length; i += 1) {
            var child = root.ownMaterializeChild(root.entries[i]);
            if (child)
                out.push(child);
        }
        return out;
    }

    function ownMaterializeChild(entry) {
        if (entry && typeof entry.toTreeObject === "function")
            return entry.toTreeObject();
        return entry || null;
    }

    function toTreeObject() {
        tracer.trace("toTreeObject", function() { return { nodeId: root.nodeId, hasSwitchActions: !!root.toggleAction }; });
        var id = root.nodeId || root.name || root.title;
        var out = {
            id: id,
            aliases: root.aliases || [],
            keywords: root.keywords || [],
            title: root.title || root.name || id,
            template: root.template,
            subtitle: root.subtitle || "",
            icon: root.icon || "",
            iconColor: root.iconColor,
            dangerous: root.dangerous,
            risk: root.risk,
            behavior: root.behavior,
            tokenPolicy: root.tokenPolicy,
            children: root.ownChildNodes(),
            replaceQuery: root.replaceQuery,
            switchActions: root.ownSwitchActions(),
            evaluationProfile: EvalProfiles.switchProfile({
                childVisible: root.childVisible || [["own-score-min", { threshold: 0.25 }]],
                retainParent: []
            })
        };
        if (root.switchState !== undefined)
            out.switchState = root.switchState;
        return out;
    }
}
