import QtQml

QtObject {
    id: root

    property string actionId: ""
    property string name: ""
    property string title: ""
    property string label: ""
    property string icon: ""
    property bool dangerous: false
    property bool isDefault: false
    property var props: ({})
    property var run: null

    function toActionPayload(fallbackId) {
        var id = root.actionId || root.name || fallbackId || "run";
        var payload = Object.assign({ actionId: id }, root.props || {});
        if (root.run)
            payload.execute = root.run;
        if (root.title)
            payload.title = root.title;
        if (root.label)
            payload.label = root.label;
        if (root.icon)
            payload.icon = root.icon;
        if (root.dangerous)
            payload.dangerous = true;
        if (root.isDefault)
            payload.default = true;
        return payload;
    }
}
