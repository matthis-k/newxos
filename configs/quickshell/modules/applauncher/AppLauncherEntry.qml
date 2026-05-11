import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: root
    required property DesktopEntry desktopEntry
    readonly property alias icon: icon
    readonly property alias textContent: textContent

    visible: !desktopEntry.noDisplay

    Item {
        id: iconWrapper
        implicitHeight: parent.height * 0.5
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        Icon {
            id: icon
            anchors.centerIn: parent
            implicitSize: parent.height
            smooth: true
            source: Quickshell.iconPath(desktopEntry?.icon, "dialog-warning")
        }
    }

    Item {
        id: textContent
        anchors.top: iconWrapper.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Text {
            id: entryName
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            horizontalAlignment: Text.AlignHCenter
            text: desktopEntry?.name || ""
            color: Config.styling.text0
            font.pixelSize: parent.height / 4
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            anchors.top: entryName.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            horizontalAlignment: Text.AlignHCenter
            text: desktopEntry?.genericName || desktopEntry?.comment || ""
            color: Config.styling.text2
            font.pixelSize: parent.height / 5
            elide: Text.ElideRight
        }
    }
}
