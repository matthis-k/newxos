import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: root
    property var shellScreenState
    readonly property bool dashboardVisible: !!shellScreenState && shellScreenState.dashboardPhase !== "closed"
    property real tabSwipeAccumulator: 0
    readonly property real tabSwipeThreshold: Config.spacing.xxl
    focusable: true

    function resetTabSwipe() {
        tabSwipeAccumulator = 0;
    }

    function queueTabSwipe(delta) {
        if (!shellScreenState || shellScreenState.dashboardPhase !== "open")
            return;

        tabSwipeAccumulator += delta;

        if (Math.abs(tabSwipeAccumulator) < tabSwipeThreshold)
            return;

        shellScreenState.stepDashboardTab(tabSwipeAccumulator < 0 ? 1 : -1);
        resetTabSwipe();
    }

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

    visible: root.dashboardVisible
    color: "transparent"

    readonly property real targetHeight: screen ? screen.height : 720
    readonly property real targetWidth: shellScreenState ? shellScreenState.dashboardWidth : 392
    readonly property real panelProgress: shellScreenState && shellScreenState.dashboardPhase === "closing" ? 0 : 1
    readonly property real backdropOpacity: shellScreenState && shellScreenState.dashboardPhase === "closing" ? 0 : 0.22

    MouseArea {
        width: panelCard.x
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        enabled: root.visible && !!root.shellScreenState && root.shellScreenState.dashboardPhase === "open"
        onClicked: {
            if (!(selection.currentItem?.popupOpen))
                root.shellScreenState?.closeDashboard();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Config.colorWithOpacity(Config.styling.bg0, 1)
        opacity: root.backdropOpacity

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
        visible: root.dashboardVisible
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: parent.width - width * root.panelProgress
        width: root.targetWidth
        height: root.targetHeight

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

        opacity: root.panelProgress

        Behavior on width {
            NumberAnimation {
                duration: Config.behaviour.animation.calc(0.2)
                easing.type: Easing.InOutCubic
            }
        }

        scale: 0.985 + 0.015 * root.panelProgress

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
            Component.onCompleted: root.syncCurrentTab()

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                orientation: Qt.Horizontal
                blocking: false

                onActiveChanged: {
                    if (!active)
                        root.resetTabSwipe();
                }

                onWheel: event => {
                    const delta = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.angleDelta.x / 4;

                    if (delta !== 0)
                        root.queueTabSwipe(delta);
                }
            }

            Overview {
                screenState: root.shellScreenState
            }
            Audio {}
            Notifications {}
            Bluetooth {}
            Network {}
            Energy {}
            Stats {}
        }

        Connections {
            target: root.shellScreenState

            function onActiveTabChanged() {
                root.resetTabSwipe();
                root.syncCurrentTab();
            }

            function onDashboardPhaseChanged() {
                if (root.shellScreenState?.dashboardPhase !== "open")
                    root.resetTabSwipe();
            }
        }
    }

    Item {
        focus: visible

        Keys.onEscapePressed: root.shellScreenState?.closeDashboard()
    }
}
