import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    property var result: ({ actions: [], children: [] })
    property bool selected: false
    property int iconSize: 32
    property bool showSubtitle: true
    property bool showActionHint: true
    property bool showEvidence: false
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
    readonly property int childCount: (result.children || []).length
    readonly property bool hasTreeChildren: childCount > 0
    property bool expanded: selected && hasTreeChildren

    signal activated(var result)

    implicitHeight: Math.max(56, mainLayout.implicitHeight + Config.spacing.xs * 2)
    color: selected ? Config.styling.selectionBackgroundActive : Config.styling.bg2
    border.color: selected ? Config.styling.primaryAccent : Config.styling.bg4
    border.width: 1
    radius: Config.styling.radius

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Config.spacing.xs
        spacing: Config.spacing.xxs

        RowLayout {
            spacing: Config.spacing.sm
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

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
                        model: [
                            { id: "on", label: qsTr("On") },
                            { id: "toggle", label: qsTr("Toggle") },
                            { id: "off", label: qsTr("Off") }
                        ]

                        Rectangle {
                            visible: root.result.switchActions && root.result.switchActions[modelData.id]
                            color: root.defaultAction && root.defaultAction.id === modelData.id
                                ? Config.colorWithOpacity(Config.styling.primaryAccent, 0.25)
                                : Config.styling.bg3
                            border.color: root.defaultAction && root.defaultAction.id === modelData.id
                                ? Config.styling.primaryAccent
                                : Config.styling.bg4
                            border.width: 1
                            radius: Config.styling.radius
                            Layout.preferredWidth: root.switchActionButtonWidth
                            Layout.preferredHeight: 20

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: Config.styling.text1
                                font.pixelSize: 10
                                font.bold: root.defaultAction && root.defaultAction.id === modelData.id
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    mouse.accepted = true;
                                    if (root.controller)
                                        root.controller.activateResultAction(root.result, modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            visible: root.expanded && root.hasTreeChildren
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? childrenColumn.implicitHeight : 0

            ColumnLayout {
                id: childrenColumn
                width: parent.width - root.iconSize - Config.spacing.sm * 2
                x: root.iconSize + Config.spacing.sm * 2
                spacing: Config.spacing.xxs

                Repeater {
                    model: root.result.children || []

                    Rectangle {
                        color: Config.styling.bg3
                        border.color: Config.styling.bg4
                        border.width: 1
                        radius: Config.styling.radius
                        Layout.fillWidth: true
                        implicitHeight: childrenLayout.implicitHeight + Config.spacing.xs * 2

                        RowLayout {
                            id: childrenLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Config.spacing.xs
                            spacing: Config.spacing.sm

                            Icon {
                                iconName: modelData.icon || root.result.icon || "application-x-executable"
                                fallbackIconName: "application-x-executable"
                                color: modelData.iconColor || root.result.iconColor || undefined
                                implicitSize: 20
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: modelData.breadcrumbText || modelData.title || ""
                                color: Config.styling.text1
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.subtitle || ""
                                visible: !!modelData.subtitle
                                color: Config.styling.text2
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        TapHandler {
                            onSingleTapped: {
                                if (controller) {
                                    var parentBreadcrumbs = Array.isArray(root.result.breadcrumbs) ? root.result.breadcrumbs : (root.result.path || []);
                                    var childResult = Object.assign({}, modelData, {
                                        source: root.result.source,
                                        category: root.result.category,
                                        breadcrumbs: parentBreadcrumbs.concat([root.result.title || ""])
                                    });
                                    controller.applyIntent(childResult, childResult.enter);
                                }
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
