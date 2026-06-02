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
    property bool showEvidence: false
    property bool showSourceBadge: false
    property var controller: null
    readonly property int switchControlWidth: 132
    readonly property int switchActionButtonWidth: 40

    readonly property var defaultAction: {
        var actions = result.actions || [];
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i].default) return actions[i];
        }
        return actions[0] || null;
    }

    signal activated(var result)

    implicitHeight: Math.max(56, row.implicitHeight + Config.spacing.xs * 2)
    color: selected ? Config.styling.selectionBackgroundActive : Config.styling.bg2
    border.color: selected ? Config.styling.primaryAccent : Config.styling.bg4
    border.width: 1
    radius: Config.styling.radius

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Config.spacing.xs
        spacing: Config.spacing.sm
        Layout.alignment: Qt.AlignVCenter

        Icon {
            iconName: root.result.icon || "application-x-executable"
            fallbackIconName: "application-x-executable"
            color: root.result.iconColor || undefined
            implicitSize: root.iconSize
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
        }

        ColumnLayout {
            spacing: Config.spacing.xxs
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: root.result.breadcrumbText || ""
                visible: text.length > 0
                color: Config.styling.text2
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: Config.spacing.xxs
                Layout.fillWidth: true

                Repeater {
                    model: root.result.breadcrumbText ? [] : root.result.breadcrumbs || root.result.path || []

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
                    visible: root.showEvidence && root.result.score > 0
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
            visible: text.length > 0 && !switchColumn.visible
            color: Config.styling.text1
            font.pixelSize: 12
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 92
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            id: switchColumn
            visible: !!root.result.switchActions
            spacing: Config.spacing.xxs
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: root.switchControlWidth
            Layout.preferredWidth: root.switchControlWidth
            Layout.maximumWidth: root.switchControlWidth

            Item {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: switchControl.implicitWidth
                Layout.preferredHeight: switchControl.implicitHeight

                DashboardToggleSwitch {
                    id: switchControl
                    checked: root.result.switchState === true
                    anchors.fill: parent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        mouse.accepted = true;
                        if (root.controller)
                            root.controller.activateResultAction(root.result, "toggle");
                    }
                }
            }

            RowLayout {
                spacing: Config.spacing.xxs
                Layout.alignment: Qt.AlignRight
                Layout.fillWidth: true

                Repeater {
                    model: ["on", "toggle", "off"]

                    Rectangle {
                        visible: root.result.switchActions && root.result.switchActions[modelData]
                        color: root.defaultAction && root.defaultAction.id === modelData
                            ? Config.colorWithOpacity(Config.styling.primaryAccent, 0.25)
                            : Config.styling.bg3
                        border.color: root.defaultAction && root.defaultAction.id === modelData
                            ? Config.styling.primaryAccent
                            : Config.styling.bg4
                        border.width: 1
                        radius: Config.styling.radius
                        Layout.preferredWidth: root.switchActionButtonWidth
                        Layout.preferredHeight: 20

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData
                            color: Config.styling.text1
                            font.pixelSize: 10
                            font.bold: root.defaultAction && root.defaultAction.id === modelData
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                mouse.accepted = true;
                                if (root.controller)
                                    root.controller.activateResultAction(root.result, modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    function scoreColor(score) {
        if (score >= 0.75) return Config.palette.green || Config.styling.success || Config.styling.primaryAccent;
        if (score >= 0.55) return Config.palette.yellow || Config.styling.warning || Config.styling.text1;
        if (score >= 0.35) return Config.palette.peach || Config.styling.warning || Config.styling.text1;
        return Config.styling.text2;
    }

    TapHandler {
        onSingleTapped: root.activated(root.result)
    }
}
