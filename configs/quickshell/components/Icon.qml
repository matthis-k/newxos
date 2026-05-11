import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property string iconName: "dialog-warning"
    property string fallbackIconName: "dialog-warning"
    property var iconPath: Quickshell.iconPath(iconName, fallbackIconName)
    property var color: undefined
    property real implicitSize: -1
    property var source: undefined

    readonly property bool hasImplicitSize: implicitSize >= 0

    implicitWidth: hasImplicitSize ? implicitSize : Math.max(16, parent ? parent.height : icon.implicitWidth)
    implicitHeight: hasImplicitSize ? implicitSize : Math.max(16, parent ? parent.height : icon.implicitHeight)

    property alias smooth: icon.smooth
    property alias mipmap: icon.mipmap

    IconImage {
        id: icon
        anchors.fill: parent
        source: root.source !== undefined ? root.source : root.iconPath
    }

    ColorOverlay {
        visible: root.color !== undefined && root.color !== null
        anchors.fill: icon
        color: visible ? root.color : "transparent"
        source: icon
        scale: icon.scale
    }
}
