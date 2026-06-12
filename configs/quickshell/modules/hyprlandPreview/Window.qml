import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.animations as Animations
import qs.utils
import qs.components
import qs.services

PanelWindow {
    id: root
    property Component previewComponent: null
    property bool previewShown: false
    property bool animateReveal: true
    property int previewGeneration: 0
    property real revealProgress: 0
    property real anchorX: (screen ? screen.width : 0) / 2
    readonly property real stripHeight: (screen ? screen.height : 720) * 0.3 + 32 + Config.spacing.md

    function clampedCardX() {
        const maxX = Math.max(0, revealFrame.width - previewCard.width);
        return Math.max(0, Math.min(maxX, anchorX - previewCard.width / 2));
    }

    function showPreview(component, sourceCenterX) {
        if (!component)
            return;

        clearAnimationTimer.stop();
        const generation = ++previewGeneration;
        animateReveal = false;
        revealProgress = 0;
        if (Number.isFinite(sourceCenterX))
            anchorX = sourceCenterX;
        previewComponent = component;
        previewShown = false;
        animateReveal = true;
        Qt.callLater(function() {
            if (root.previewGeneration === generation && root.previewComponent === component) {
                root.previewShown = true;
                root.revealProgress = 1;
            }
        });

        if (selection.currentIndex !== 0)
            selection.setCurrentIndex(0);
    }

    function clearPreview() {
        if (!previewComponent)
            return;

        previewShown = false;
        revealProgress = 0;
        if (Config.motion.medium <= 0)
            finishClearPreview();
        else
            clearAnimationTimer.restart();
    }

    function finishClearPreview() {
        previewComponent = null;
    }

    anchors {
        top: true
        left: true
    }
    implicitWidth: screen ? screen.width : (previewLoader.item ? previewLoader.item.implicitWidth + Config.spacing.md : 0)
    implicitHeight: stripHeight

    visible: root.revealProgress > 0 || !!previewLoader.item
    color: "transparent"

    Animations.PanelBehavior on revealProgress {
        enabled: root.animateReveal
    }

    Component.onCompleted: {
        if (WlrLayershell)
            WlrLayershell.layer = WlrLayer.Overlay;
    }

    Item {
        id: revealFrame
        anchors.fill: parent
        clip: true

        Item {
            id: previewCard
            width: previewLoader.item ? previewLoader.item.implicitWidth + Config.spacing.md : 0
            height: previewLoader.item ? previewLoader.item.implicitHeight + Config.spacing.md : 0
            x: root.clampedCardX()
            y: -height * (1 - root.revealProgress)

            Rectangle {
                anchors.fill: parent
                color: Config.styling.bg0
                radius: Config.styling.radius
            }

            SwipeView {
                id: selection
                anchors.fill: parent
                anchors.margins: Config.spacing.xs
                interactive: false
                clip: true

                Item {
                    id: previewPage
                    implicitWidth: previewLoader.item ? previewLoader.item.implicitWidth : 0
                    implicitHeight: previewLoader.item ? previewLoader.item.implicitHeight : 0

                    Loader {
                        id: previewLoader
                        anchors.centerIn: parent
                        sourceComponent: root.previewComponent
                    }
                }
            }
        }
    }

    property int externalHovers: 0
    readonly property bool deferredClose: !(hoverHandler.hovered || externalHovers > 0)
    onDeferredCloseChanged: deferredClose ? closeTimer.start() : closeTimer.stop()

    HoverHandler {
        id: hoverHandler
        target: previewCard
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: root.clearPreview()
    }

    Timer {
        id: clearAnimationTimer
        interval: Config.motion.medium
        onTriggered: root.finishClearPreview()
    }
}
