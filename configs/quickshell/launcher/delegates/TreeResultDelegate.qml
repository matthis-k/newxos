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
    property bool showSourceBadge: false
    property var controller: null

    property bool expanded: selected
    readonly property var defaultAction: {
        var actions = result.actions || [];
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i].default) return actions[i];
        }
        return actions[0] || null;
    }
    readonly property int childCount: (result.children || []).length

    signal activated(var result)

    implicitHeight: Math.max(64, mainColumn.implicitHeight + Config.spacing.xs * 2)
    color: selected ? Config.styling.selectionBackgroundActive : Config.styling.bg2
    border.color: selected ? Config.styling.primaryAccent : Config.styling.bg4
    border.width: 1
    radius: Config.styling.radius

    ColumnLayout {
        id: mainColumn
        anchors.centerIn: parent
        width: parent.width - Config.spacing.xs * 2
        height: implicitHeight
        spacing: Config.spacing.xxs

        RowLayout {
            spacing: Config.spacing.sm
            Layout.fillWidth: true
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

        Item {
            id: childrenContainer
            visible: root.expanded && root.childCount > 0
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? childrenColumn.implicitHeight : 0
            implicitHeight: visible ? childrenColumn.implicitHeight : 0

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
                        implicitHeight: 32

                        RowLayout {
                            anchors.fill: parent
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

    TapHandler {
        onSingleTapped: root.activated(root.result)
    }
}
