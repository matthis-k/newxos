import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.utils

PanelWindow {
    anchors {
        top: true
        right: true
        left: true
    }
    Component.onCompleted: {
        if (WlrLayershell)
            WlrLayershell.layer = WlrLayer.Top;
    }
    implicitHeight: Math.round(Pixels.mm(10, screen)) | 1
    Bar {}

    function open() {
        visible = true;
    }
    function close() {
        visible = false;
    }
    function toggle() {
        visible = !visible;
    }
}
