import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.utils
import qs.components
import qs.services

PanelWindow {
    id: root
    property Component previewComponent: null

    function showPreview(component) {
        if (!component)
            return;

        previewComponent = component;
        if (selection.currentIndex !== 0)
            selection.setCurrentIndex(0);
    }

    function clearPreview() {
        previewComponent = null;
    }

    anchors {
        top: true
        left: true
    }
    implicitWidth: previewLoader.item ? previewLoader.item.implicitWidth + Config.spacing.md : 0
    implicitHeight: previewLoader.item ? previewLoader.item.implicitHeight + Config.spacing.md : 0

    visible: !!previewLoader.item
    color: Config.styling.bg0

    Component.onCompleted: {
        if (WlrLayershell)
            WlrLayershell.layer = WlrLayer.Overlay;
    }

    SwipeView {
        id: selection
        anchors.centerIn: parent
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

    property int externalHovers: 0
    readonly property bool _deferredClose: !(hoverHandler.hovered || externalHovers > 0)
    on_DeferredCloseChanged: _deferredClose ? closeTimer.start() : closeTimer.stop()

    HoverHandler {
        id: hoverHandler
        target: previewPage
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: root.clearPreview()
    }
}
