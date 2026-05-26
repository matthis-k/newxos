import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    property var result: ({ actions: [] })
    property bool selected: false
    property int iconSize: 32
    property bool showSubtitle: true
    property bool showActionHint: true
    property bool showSourceBadge: false
    property var controller: null

    readonly property var defaultAction: (result.actions || []).find(action => action.default) || (result.actions || [])[0]

    signal activated(var result)

    color: selected ? Config.styling.selectionBackgroundActive : "transparent"
    radius: Config.styling.radius

    RowLayout {
        anchors.fill: parent
        anchors.margins: Config.spacing.xs
        spacing: Config.spacing.sm

        Icon {
            iconName: root.result.icon || "application-x-executable"
            fallbackIconName: "application-x-executable"
            implicitSize: root.iconSize
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
        }

        ColumnLayout {
            spacing: Config.spacing.xxs
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: root.result.title || ""
                color: Config.styling.text0
                font.pixelSize: 15
                font.bold: root.selected
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }

            Text {
                text: root.result.subtitle || ""
                visible: root.showSubtitle && !!root.result.subtitle
                color: Config.styling.text1
                font.pixelSize: 12
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }
        }

        Text {
            text: root.showActionHint && root.defaultAction ? root.defaultAction.label : ""
            visible: text.length > 0
            color: Config.styling.text1
            font.pixelSize: 12
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 92
            Layout.alignment: Qt.AlignVCenter
        }
    }

    TapHandler {
        onSingleTapped: root.activated(root.result)
    }
}
