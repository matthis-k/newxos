import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.components

Item {
    id: root

    required property HyprlandToplevel toplevel
    property real screenFraction: 0.3

    readonly property real screenWidth: screen.width
    readonly property real screenHeight: screen.height
    readonly property real maxViewWidth: screenWidth * screenFraction
    readonly property real maxViewHeight: screenHeight * screenFraction

    implicitWidth: (screencopyView.implicitWidth || maxViewWidth)
    implicitHeight: (screencopyView.implicitHeight || maxViewHeight) + header.height

    Item {
        id: header
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: screencopyView.width
        height: 32

        Icon {
            id: appIcon
            property DesktopEntry entry: {
                DesktopEntries.applications?.values;
                return DesktopEntries.heuristicLookup(root.toplevel?.wayland?.appId);
            }
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: height
            source: Quickshell.iconPath(entry?.icon || "dialog-warning", "dialog-warning")
            mipmap: false
            scale: Config.styling.statusIconScaler
        }

        Text {
            text: root.toplevel.title || root.toplevel?.wayland.title
            color: Config.styling.text0
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
            anchors.left: appIcon.right
            anchors.leftMargin: Config.spacing.xxs
            anchors.right: closeBtn.left
            anchors.verticalCenter: parent.verticalCenter
        }

        InteractiveButton {
            id: closeBtn
            width: 32
            height: 32
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            scaleTarget: null
            scaleIcon: true
            iconScaleTarget: icon
            hoveredScale: 1.0
            unhoveredScale: 0.8

            onClicked: {
                root.toplevel?.wayland?.close();
                ShellState.getScreenByName(screen.name).hyprlandPreview.clearPreview();
            }

            contentItem: Icon {
                id: icon
                anchors.fill: parent
                iconName: "window-close"
                fallbackIconName: "window-close"
                color: Config.styling.close || Config.colors.red
            }
        }
    }

    ScreencopyView {
        id: screencopyView
        captureSource: root.toplevel?.wayland
        constraintSize: Qt.size(root.maxViewWidth, root.maxViewHeight)
        width: implicitWidth || root.maxViewWidth
        height: implicitHeight || root.maxViewHeight
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        live: true

        TapHandler {
            onSingleTapped: {
                root.toplevel?.wayland?.activate();
                ShellState.getScreenByName(screen.name).hyprlandPreview.clearPreview();
            }
        }
    }
}
