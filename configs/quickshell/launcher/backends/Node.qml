import QtQml

QtObject {
    id: root

    default property list<QtObject> entries

    property string nodeId: ""
    property string name: ""
    property string template: ""
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property var iconColor: null
    property var aliases: []
    property var keywords: []
    property var dynamicChildren: []
    property bool dangerous: false
    property var behavior: null
    property var groupOptions: ({})
    property var tokenPolicy: null
    property var action: null
    property var actionProps: ({})
    property string actionId: ""
    property var switchState: undefined
    property var replaceQuery: null

    function childNodes() {
        var out = [];
        for (var ci = 0; ci < (root.dynamicChildren || []).length; ci += 1)
            out.push(materializeChild(root.dynamicChildren[ci]));
        for (var i = 0; i < root.entries.length; i += 1) {
            var entry = root.entries[i];
            var child = materializeChild(entry);
            if (child)
                out.push(child);
        }
        return out;
    }

    function materializeChild(entry) {
        if (entry && typeof entry.toTreeObject === "function")
            return entry.toTreeObject();
        return entry || null;
    }

    function ownAction() {
        var id = root.actionId || root.nodeId || root.name || "run";
        if (typeof root.action === "function") {
            var payload = Object.assign({ actionId: id }, root.actionProps || {});
            payload.execute = root.action;
            return payload;
        }
        if (root.action && typeof root.action === "object")
            return Object.assign({ actionId: id }, root.action);
        return null;
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
            behavior: root.behavior,
            groupOptions: root.groupOptions || {},
            tokenPolicy: root.tokenPolicy,
            children: childNodes(),
            replaceQuery: root.replaceQuery
        };
        if (root.switchState !== undefined)
            out.switchState = root.switchState;
        var payload = ownAction();
        if (payload)
            out.action = payload;
        return out;
    }
}
