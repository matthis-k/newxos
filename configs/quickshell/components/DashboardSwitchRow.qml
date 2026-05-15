import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string label: ""
    property string subtitle: ""
    property string iconName: ""
    property color iconColor: Config.styling.text0
    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(44, row.implicitHeight + Config.spacing.xs * 2)

    Rectangle {
        anchors.fill: parent
        color: Config.styling.bg3
        radius: Config.styling.radius
    }

    MouseArea {
        anchors.fill: parent
        z: 2
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Config.spacing.xs
        spacing: Config.spacing.sm

        Icon {
            visible: root.iconName !== ""
            iconName: root.iconName
            color: root.iconColor
            implicitSize: 18
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.label
                color: Config.styling.text0
                font.pixelSize: 14
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

        Item {
            Layout.preferredWidth: 38
            Layout.minimumWidth: 38
            Layout.maximumWidth: 38
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: !root.enabled
                    ? Config.styling.bg4
                    : root.checked
                        ? Config.styling.primaryAccent
                        : Config.styling.bg5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    Item {
                        Layout.fillWidth: !root.checked
                    }

                    Rectangle {
                        Layout.preferredWidth: 18
                        Layout.minimumWidth: 18
                        Layout.maximumWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter
                        radius: 9
                        color: Config.styling.textOnAccent
                    }

                    Item {
                        Layout.fillWidth: root.checked
                    }
                }
            }
        }
    }
}
