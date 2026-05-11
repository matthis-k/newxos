import QtQuick
import qs.services

Item {
    id: root

    required property string title

    implicitWidth: 320
    implicitHeight: 160

    Rectangle {
        anchors.fill: parent
        color: Config.styling.bg1
        border.width: 1
        border.color: Config.styling.bg4
    }

    Text {
        anchors.centerIn: parent
        text: `${root.title} settings coming back soon`
        color: Config.styling.text1
        font.pixelSize: 18
        font.bold: true
    }
}
