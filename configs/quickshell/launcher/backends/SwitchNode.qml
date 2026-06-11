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
            groupOptions: root.groupOptions || {},
            tokenPolicy: root.tokenPolicy,
            children: root.ownChildNodes(),
            replaceQuery: root.replaceQuery,
            switchActions: root.ownSwitchActions(),
            evaluationProfile: {
                mode: "generic+custom",
                strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"],
                scorePolicy: "default",
                profile: {
                    evidence: ["field-match:primary", "field-match:breadcrumb", "switch-action"],
                    inherit: [],
                    boost: ["descendant-boost", "switch-aliases"],
                    childVisible: root.childVisible || ["own-score-min:0.25"],
                    childBypass: ["score-dominates:0.03"]
                }
            }
        };
        if (root.switchState !== undefined)
            out.switchState = root.switchState;
        return out;
    }
}
