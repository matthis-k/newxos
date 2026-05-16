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
            : column.implicitHeight + root.pagePadding * 2
        clip: true

        ColumnLayout {
            id: column
            anchors {
                fill: parent
                margins: root.pagePadding
            }
            spacing: root.sectionSpacing

            DashboardPageHeader {
                id: header
                Layout.fillWidth: true
                visible: root.title !== "" || root.subtitle !== "" || root.headerAccessory !== null
                title: root.title
                subtitle: root.subtitle
                accessory: root.headerAccessory
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                spacing: root.sectionSpacing
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: root.scrollable && root.fillHeight
            }
        }
    }
}
