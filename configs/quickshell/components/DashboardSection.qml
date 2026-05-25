import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool collapsible: false
    property bool collapsed: false
    property Component summary: null
    property Component headerAccessory: null
    property bool showHeader: title !== "" || subtitle !== "" || summary !== null || headerAccessory !== null || collapsible
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
            accessory: headerAccessoryComponent
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.showHeader && !root.collapsed
            implicitHeight: 1
            color: Config.styling.bg3
        }

        DashboardSectionContent {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            visible: !root.collapsed
            contentSpacing: root.contentSpacing
        }
    }

    Component {
        id: headerAccessoryComponent

        RowLayout {
            spacing: Config.spacing.xs

            Loader {
                active: root.summary !== null
                sourceComponent: root.summary
                Layout.preferredWidth: item ? item.implicitWidth : 0
                Layout.preferredHeight: item ? item.implicitHeight : 0
                Layout.alignment: Qt.AlignVCenter
            }

            Loader {
                active: root.headerAccessory !== null
                sourceComponent: root.headerAccessory
                Layout.preferredWidth: item ? item.implicitWidth : 0
                Layout.preferredHeight: item ? item.implicitHeight : 0
                Layout.alignment: Qt.AlignVCenter
            }

            DashboardIconButton {
                visible: root.collapsible
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                iconName: root.collapsed ? "go-next-symbolic" : "go-down-symbolic"
                fallbackIconName: iconName
                iconColor: hovered ? Config.styling.activeIndicator : Config.styling.text0
                backgroundColor: hovered ? Config.styling.bg3 : Config.styling.bg2
                active: hovered
                fillOnHover: true
                indicatorOnHover: false
                onClicked: root.collapsed = !root.collapsed
            }
        }
    }
}
