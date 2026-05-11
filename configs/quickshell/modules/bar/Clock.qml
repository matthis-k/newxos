import QtQuick
import qs.services

Item {
    property string format: "HH:mm"
    implicitHeight: parent.height
    implicitWidth: txt.implicitWidth
    Text {
        id: txt
        anchors.verticalCenter: parent.verticalCenter
        anchors.fill: parent
        text: Time.formatted(format)
        color: Config.styling.text0
        font.bold: true
        font.pixelSize: Math.round(parent.height * 0.8)
        verticalAlignment: Qt.AlignVCenter
    }
}
