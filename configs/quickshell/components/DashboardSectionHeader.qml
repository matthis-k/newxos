import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string title: ""
    property string subtitle: ""

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Config.spacing.xs

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.title
                color: Config.styling.text0
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                visible: text !== ""
                text: root.subtitle
                color: Config.styling.text2
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
}
