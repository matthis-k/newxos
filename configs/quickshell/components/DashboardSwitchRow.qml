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
    property int switchSlotWidth: 46

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
            Layout.preferredWidth: root.switchSlotWidth
            Layout.minimumWidth: root.switchSlotWidth
            Layout.maximumWidth: root.switchSlotWidth
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter

            DashboardToggleSwitch {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                checked: root.checked
                enabled: root.enabled
                onToggled: root.toggled(checked)
            }
        }
    }
}
