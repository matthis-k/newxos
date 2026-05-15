import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property Component headerAccessory: null
    property bool scrollable: false
    property bool fillHeight: true
    property int pagePadding: Config.spacing.md
    property int sectionSpacing: Config.spacing.md
    default property alias content: body.data

    implicitWidth: 360
    implicitHeight: column.implicitHeight + pagePadding * 2

    Flickable {
        id: flick
        anchors.fill: parent
        interactive: root.scrollable
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: root.scrollable
            ? Math.max(column.implicitHeight + root.pagePadding * 2, height)
            : height
        clip: true

        ColumnLayout {
            id: column
            x: root.pagePadding
            y: root.pagePadding
            width: Math.max(0, flick.width - root.pagePadding * 2)
            height: root.scrollable
                ? implicitHeight
                : Math.max(0, flick.height - root.pagePadding * 2)
            spacing: root.sectionSpacing

            DashboardPageHeader {
                id: header
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                visible: root.title !== "" || root.subtitle !== "" || root.headerAccessory !== null
                title: root.title
                subtitle: root.subtitle
                accessory: root.headerAccessory
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                Layout.fillHeight: !root.scrollable
                Layout.alignment: Qt.AlignTop
                width: column.width
                spacing: root.sectionSpacing
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: root.scrollable && root.fillHeight
                    ? Math.max(0, flick.height - root.pagePadding * 2 - header.implicitHeight - body.implicitHeight - (header.visible ? root.sectionSpacing : 0))
                    : 0
            }
        }
    }
}
