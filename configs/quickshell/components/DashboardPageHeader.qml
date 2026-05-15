import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool showDivider: title !== "" || subtitle !== ""

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: Config.spacing.xs

        Text {
            visible: text !== ""
            text: root.title
            color: Config.styling.text0
            font.pixelSize: 22
            font.bold: true
        }

        Text {
            visible: text !== ""
            text: root.subtitle
            color: Config.styling.text2
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        Rectangle {
            visible: root.showDivider
            Layout.fillWidth: true
            implicitHeight: 1
            color: Config.styling.bg3
        }
    }
}
