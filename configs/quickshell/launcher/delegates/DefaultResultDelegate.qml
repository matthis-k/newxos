import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import "../logic/EvidenceScorer.js" as EvidenceScorer

Rectangle {
    id: root

    property var result: ({ actions: [] })
    property bool selected: false
    property int iconSize: 32
    property bool showSubtitle: true
    property bool showActionHint: true
    property bool showSourceBadge: false
    property var controller: null

    readonly property var defaultAction: {
        var actions = result.actions || [];
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i].default) return actions[i];
        }
        return actions[0] || null;
    }

    signal activated(var result)

    color: selected ? Config.styling.selectionBackgroundActive : "transparent"
    radius: Config.styling.radius

    RowLayout {
        anchors.fill: parent
        anchors.margins: Config.spacing.xs
        spacing: Config.spacing.sm
        Layout.alignment: Qt.AlignVCenter

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

            RowLayout {
                spacing: Config.spacing.xxs
                Layout.fillWidth: true

                Repeater {
                    model: root.result.breadcrumbs || root.result.path || []

                    RowLayout {
                        spacing: Config.spacing.xxs

                        Text {
                            text: modelData
                            color: Config.styling.text1
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Icon {
                            iconName: "pan-end-symbolic"
                            fallbackIconName: "pan-end-symbolic"
                            implicitSize: 10
                            Layout.preferredWidth: 10
                            Layout.preferredHeight: 10
                        }
                    }
                }

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
                    text: root.result.score ? Math.round(root.result.score * 100) + "%" : ""
                    visible: root.result.score > 0
                    color: scoreColor(root.result.score)
                    font.pixelSize: 10
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 28
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Text {
                text: root.result.subtitle || ""
                visible: root.showSubtitle && text.length > 0
                color: Config.styling.text2
                font.pixelSize: 11
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

    function scoreColor(score) {
        if (score >= 0.90) return "#a6e3a1";
        if (score >= 0.75) return "#a6e3a1";
        if (score >= 0.55) return "#f9e2af";
        if (score >= 0.35) return "#fab387";
        return Config.styling.text2;
    }

    TapHandler {
        onSingleTapped: root.activated(root.result)
    }
}
