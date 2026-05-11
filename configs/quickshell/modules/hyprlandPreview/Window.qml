import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.utils
import qs.components
import qs.services

PanelWindow {
    id: win
    property alias view: selectView.currentView
    property alias views: selectView

    anchors {
        top: true
        left: true
    }
    Component.onCompleted: {
        if (WlrLayershell)
            WlrLayershell.layer = WlrLayer.Overlay;
    }

    implicitWidth: selectView.currentItem?.implicitWidth + 16 || 0
    implicitHeight: selectView.currentItem?.implicitHeight + 16 || 0

    visible: !!selectView.currentItem
    color: Config.styling.bg0

    SelectView {
        id: selectView
        anchors.centerIn: parent
        currentView: "hyprlandPreview"
    }

    property int externalHovers: 0
    readonly property bool _deferredClose: !(hoverHandler.hovered || externalHovers > 0)
    on_DeferredCloseChanged: _deferredClose ? closeTimer.start() : closeTimer.stop()

    HoverHandler {
        id: hoverHandler
        target: selectView
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: {
            selectView.remove("hyprlandPreview");
        }
    }
}
