import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

PanelWindow {
    id: backgroundWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Config.styling.bg0
    focusable: false
    visible: true

    property alias wallpaperPath: wallpaperItem.source

    Item {
        anchors.fill: parent
        Image {
            id: wallpaperItem
            anchors.fill: parent
            source: Config.wallpaper
            visible: !!Config.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }

    Component.onCompleted: {
        if (WlrLayershell) {
            WlrLayershell.layer = WlrLayer.Background;
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
        }
    }
}
