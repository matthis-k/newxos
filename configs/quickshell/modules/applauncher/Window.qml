import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.components
import "."

PanelWindow {
    id: win
    focusable: true

    color: "transparent"
    visible: false

    implicitWidth: launcher.implicitWidth
    implicitHeight: launcher.implicitHeight

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

    AppLauncher {
        id: launcher
        anchors.centerIn: parent
    }

    function open() {
        launcher.currentView = "appsearch";
        launcher.get("appsearch").searchTerm = "";
        launcher.remove("details");
        visible = true;
    }

    function close() {
        visible = false;
    }

    function toggle() {
        if (visible) {
            close();
        } else {
            open();
        }
    }
}
