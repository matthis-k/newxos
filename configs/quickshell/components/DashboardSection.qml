import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool showHeader: title !== "" || subtitle !== ""
    property int sectionPadding: Config.spacing.xs
    property int contentSpacing: Config.spacing.xs
    default property alias content: body.data

    color: Config.styling.bg1
    radius: Config.styling.radius
    clip: true
    implicitWidth: Math.max(header.implicitWidth, body.implicitWidth) + sectionPadding * 2
    implicitHeight: layout.implicitHeight + sectionPadding * 2

    Behavior on height {
        NumberAnimation {
            duration: Config.behaviour.animation.enabled
                ? Config.behaviour.animation.calc(0.18)
                : 0
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: root.sectionPadding
        spacing: Config.spacing.xs

        DashboardSectionHeader {
            id: header
            Layout.fillWidth: true
            visible: root.showHeader
            title: root.title
            subtitle: root.subtitle
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.showHeader
            implicitHeight: 1
            color: Config.styling.bg3
        }

        DashboardSectionContent {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            contentSpacing: root.contentSpacing
        }
    }
}
