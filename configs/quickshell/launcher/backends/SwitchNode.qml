ActionGroupNode {
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

    dynamicChildren: root.buildSwitchChildren()

    function buildSwitchChildren() {
        var out = [];
        var id = root.switchActionId || root.actionId || root.name || "run";
        var onAliases = root.switchOnAliases.length > 0 ? root.switchOnAliases : root.defaultSwitchAlias("on");
        var offAliases = root.switchOffAliases.length > 0 ? root.switchOffAliases : root.defaultSwitchAlias("off");
        var toggleAliases = root.switchToggleAliases.length > 0 ? root.switchToggleAliases : root.defaultSwitchAlias("toggle");
        var child = root.switchChild("on", true, onAliases, id, root.onAction, false);
        if (child) out.push(child);
        child = root.switchChild("off", false, offAliases, id, root.offAction, root.switchOffDangerous);
        if (child) out.push(child);
        child = root.switchChild("toggle", null, toggleAliases, id, root.toggleAction, false);
        if (child) out.push(child);
        return out;
    }

    function defaultSwitchAlias(kind) {
        var letter = (root.aliases && root.aliases.length > 0 ? String(root.aliases[0]) : root.name || "x").charAt(0).toLowerCase();
        var suffix = kind === "on" ? "o" : kind === "off" ? "f" : "t";
        return [letter + suffix];
    }

    function switchChild(kind, state, aliases, actionId, actionFn, dangerous) {
        if (typeof actionFn !== "function")
            return null;
        return {
            id: actionId + ":" + kind,
            title: kind === "on" ? qsTr("Turn On") : kind === "off" ? qsTr("Turn Off") : qsTr("Toggle"),
            subtitle: "",
            icon: kind === "on" ? "object-select-symbolic" : kind === "off" ? "window-close-symbolic" : "view-refresh-symbolic",
            iconColor: null,
            aliases: aliases || [],
            template: "action",
            keywords: [],
            dangerous: dangerous,
            children: [],
            behavior: null,
            groupOptions: ({}),
            tokenPolicy: null,
            replaceQuery: null,
            action: { actionId: actionId, state: state, execute: actionFn }
        };
    }
}
