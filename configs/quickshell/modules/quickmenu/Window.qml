import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.utils
import qs.utils.types
import qs.components
import qs.services

PanelWindow {
    id: win
    property alias view: selection.currentView

    anchors {
        top: true
        right: true
    }
    Component.onCompleted: {
        if (WlrLayershell)
            WlrLayershell.layer = WlrLayer.Overlay;
    }

    implicitWidth: selection.currentItem?.implicitWidth + 16 || 0
    implicitHeight: selection.currentItem?.implicitHeight + 16 || 0
    visible: !!selection.currentItem
    color: Config.styling.bg0

    SelectView {
        id: selection
        anchors.centerIn: parent
        SimpleMap.Entry {
            key: "power"
            value: Power {}
        }
        SimpleMap.Entry {
            key: "battery"
            value: Battery {}
        }
        SimpleMap.Entry {
            key: "network"
            value: Network {}
        }
        SimpleMap.Entry {
            key: "bluetooth"
            value: Bluetooth {}
        }
        SimpleMap.Entry {
            key: "audio"
            value: Audio {}
        }
    }

    property int externalHovers: 0
    readonly property bool _deferredClose: !(hoverHandler.hovered || externalHovers > 0)
    on_DeferredCloseChanged: _deferredClose ? closeTimer.start() : closeTimer.stop()

    HoverHandler {
        id: hoverHandler
        target: selection
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: {
            selection.currentView = null;
        }
    }
}
