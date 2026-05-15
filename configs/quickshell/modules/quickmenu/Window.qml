import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.services

PanelWindow {
    id: win
    property var shellScreenState
    readonly property bool dashboardVisible: !!shellScreenState && shellScreenState.dashboardPhase !== "closed"
    focusable: true

    function syncCurrentTab() {
        if (!shellScreenState)
            return;

        const targetIndex = shellScreenState.tabIndex(shellScreenState.activeTab);
        if (selection.currentIndex !== targetIndex)
            selection.setCurrentIndex(targetIndex);
    }

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }
    Component.onCompleted: {
        if (WlrLayershell)
            WlrLayershell.layer = WlrLayer.Overlay;
    }

    visible: win.dashboardVisible
    color: "transparent"

    readonly property real targetHeight: screen ? screen.height : 720
    readonly property real targetWidth: shellScreenState ? shellScreenState.dashboardWidth : 392
    readonly property real panelProgress: shellScreenState && shellScreenState.dashboardPhase === "closing" ? 0 : 1
    readonly property real backdropOpacity: shellScreenState && shellScreenState.dashboardPhase === "closing" ? 0 : 0.22

    MouseArea {
        width: panelCard.x
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        enabled: win.visible && !!win.shellScreenState && win.shellScreenState.dashboardPhase === "open"
        onClicked: {
            if (!(selection.currentItem?.popupOpen))
                win.shellScreenState?.closeDashboard();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Config.colorWithOpacity(Config.styling.bg0, 1)
        opacity: win.backdropOpacity

        Behavior on opacity {
            NumberAnimation {
                duration: Config.behaviour.animation.enabled
                    ? Config.behaviour.animation.calc(0.18)
                    : 0
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: panelCard
        z: 1
        visible: win.dashboardVisible
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: parent.width - width * win.panelProgress
        width: win.targetWidth
        height: win.targetHeight

        Behavior on x {
            NumberAnimation {
                duration: Config.behaviour.animation.calc(0.2)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Config.behaviour.animation.calc(0.12)
                easing.type: Easing.OutCubic
            }
        }

        opacity: win.panelProgress

        Behavior on width {
            NumberAnimation {
                duration: Config.behaviour.animation.calc(0.2)
                easing.type: Easing.InOutCubic
            }
        }

        scale: 0.985 + 0.015 * win.panelProgress

        Behavior on scale {
            NumberAnimation {
                duration: Config.behaviour.animation.enabled
                    ? Config.behaviour.animation.calc(0.18)
                    : 0
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Config.styling.bg0
            radius: Config.styling.radius
        }

        SwipeView {
            id: selection
            anchors.fill: parent
            interactive: false
            clip: true
            Component.onCompleted: win.syncCurrentTab()

            Overview {
                screenState: win.shellScreenState
            }
            Audio {}
            Notifications {}
            Bluetooth {}
            Network {}
            Energy {}
            Stats {}
        }

        Connections {
            target: win.shellScreenState

            function onActiveTabChanged() {
                win.syncCurrentTab();
            }
        }
    }

    Item {
        focus: visible

        Keys.onEscapePressed: win.shellScreenState?.closeDashboard()
    }
}
