import QtQml

ActionNode {
    id: root

    property var state: null
    property bool dangerousOff: true

    name: root.state === true ? "on" : root.state === false ? "off" : "toggle"
    aliases: []
    title: root.state === true ? qsTr("Turn On") : root.state === false ? qsTr("Turn Off") : qsTr("Toggle")
    icon: root.state === true ? "object-select-symbolic" : root.state === false ? "window-close-symbolic" : "view-refresh-symbolic"
    dangerous: root.state === false && root.dangerousOff
    actionProps: ({ state: root.state })
}
