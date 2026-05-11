import QtQuick
import Quickshell
import qs.services
import qs.components
import qs.modules.quickmenu

InteractiveButton {
    id: root
    property var quickmenuName
    property alias iconName: icon.iconName
    property alias fallbackIconName: icon.fallbackIconName
    property alias source: icon.source
    property alias color: icon.color
    property alias iconSize: icon.implicitSize
    property alias smooth: icon.smooth
    property alias mipmap: icon.mipmap

    implicitWidth: iconSize >= 0 ? iconSize : Math.max(16, parent ? parent.height : icon.implicitWidth)
    implicitHeight: iconSize >= 0 ? iconSize : Math.max(16, parent ? parent.height : icon.implicitHeight)
    scaleTarget: null
    scaleIcon: true
    iconScaleTarget: icon
    baseScale: Config.styling.statusIconScaler
    hoveredScale: 1.0 / Math.max(0.001, baseScale)
    unhoveredScale: 1.0
    padding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: Icon {
        id: icon
        anchors.centerIn: parent
        color: Config.styling.text0
    }

    onHoveredChanged: {
        if (!quickmenuName) {
            return;
        }
        let qm = ShellState.getScreenByName(screen.name).quickmenu;
        if (hovered) {
            qm.view = quickmenuName;
        }
        qm.externalHovers += hovered ? 1 : -1;
    }
}
