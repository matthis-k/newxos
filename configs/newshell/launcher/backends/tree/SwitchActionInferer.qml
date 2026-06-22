import QtQml

QtObject {
    id: root

    property var nodeFactory: null

    function switchActionMap(node, children) {
        const byState = {};
        for (const child of children || []) {
            const leafAction = child.actionList && child.actionList[0];
            const payload = leafAction && leafAction.payload || {};
            const id = String(child.label || child.id || "").toLowerCase();
            if (!leafAction)
                continue;
            if (!byState.toggle && (payload.state === null || id.indexOf("toggle") >= 0))
                byState.toggle = root._makeActionDto("toggle", qsTr("Toggle"), leafAction.payload || leafAction);
            else if (!byState.off && (payload.state === false || payload.state === "disconnect" || id.indexOf("off") >= 0 || id.indexOf("disable") >= 0 || id.indexOf("disconnect") >= 0))
                byState.off = root._makeActionDto("off", qsTr("Off"), leafAction.payload || leafAction);
            else if (!byState.on && (payload.state === true || payload.state === "connect" || id.indexOf("on") >= 0 || id.indexOf("enable") >= 0 || id.indexOf("connect") >= 0))
                byState.on = root._makeActionDto("on", qsTr("On"), leafAction.payload || leafAction);
        }
        return byState.on && byState.off && byState.toggle ? byState : null;
    }

    function actionDtosForSwitchActions(switchActions) {
        if (!switchActions)
            return null;
        var out = {};
        for (var key in switchActions) {
            var action = switchActions[key];
            if (!action)
                continue;
            out[key] = root._makeActionDto(action.id || key, action.title || action.label || key, action.payload || action);
        }
        return out;
    }

    function _makeActionDto(id, label, payload) {
        if (root.nodeFactory)
            return root.nodeFactory.actionDto(id, label, payload);
        return { id: id, label: label || id, icon: null, default: false, payload: payload || null };
    }
}
