import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services

ScrollView {
    id: root

    property int contentSpacing: Config.spacing.xs
    default property alias content: contentColumn.data

    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    background: Rectangle {
        color: "transparent"
    }

    ColumnLayout {
        id: contentColumn
        width: root.availableWidth > 0 ? root.availableWidth : root.width
        spacing: root.contentSpacing
    }
}
