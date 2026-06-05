import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    required property TreeView treeView
    required property bool isTreeNode
    required property bool expanded
    required property bool hasChildren
    required property int depth
    required property int row
    required property int column
    required property bool current

    property var controller: null
    property int rowHeight: 40
    readonly property string title: cell(0) || ""
    readonly property string subtitle: cell(1) || ""
    readonly property string iconName: cell(2) || ""
    readonly property var iconColor: cell(3) || undefined
    readonly property var switchState: cell(4)
    readonly property bool hasActions: !!cell(5)
    readonly property bool hasSwitchActions: !!cell(6)
    readonly property string defaultActionLabel: cell(7) || ""
    readonly property string key: cell(9) || ""
    readonly property bool lazy: !!cell(11)
    readonly property bool active: root.controller && root.controller.activeNodeKey === root.key

    function cell(column) {
        if (!root.treeView || !root.treeView.model)
            return null;
        return root.treeView.model.data(root.treeView.index(root.row, column), "display");
    }

    implicitHeight: root.rowHeight

    onCurrentChanged: {
        if (root.current && root.controller) {
            root.controller.currentTreeView = root.treeView;
            root.controller.treeVisualRow = root.row;
            root.controller.currentTreeKey = root.key;
            root.controller.activeNodeKey = root.key;
        }
    }
    color: root.active ? Config.styling.selectionBackgroundActive : Config.styling.bg3
    border.color: root.active ? Config.styling.primaryAccent : Config.styling.bg4
    border.width: 1
    radius: Config.styling.radius

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Config.spacing.xs + root.depth * Config.spacing.sm
        anchors.rightMargin: Config.spacing.xs
        spacing: Config.spacing.sm

        Item {
            implicitWidth: 12
            implicitHeight: 12
            visible: root.hasChildren

            Icon {
                anchors.fill: parent
                iconName: root.expanded ? "pan-down-symbolic" : "pan-end-symbolic"
                color: Config.styling.text1
            }

            TapHandler {
                onSingleTapped: {
                    root.selectThisRow();
                    if (root.lazy && !root.expanded) {
                        if (root.controller)
                            root.controller.loadLazyChildren(root.key);
                    } else {
                        root.treeView.toggleExpanded(root.row);
                    }
                }
            }
        }

        Icon {
                iconName: root.iconName || "application-x-executable"
                fallbackIconName: "application-x-executable"
                color: root.iconColor
            implicitSize: 20
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }

        ColumnLayout {
            spacing: Config.spacing.xxs
            Layout.fillWidth: true

            Text {
                text: root.title
                color: Config.styling.text1
                font.pixelSize: 13
                font.bold: root.active
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }

            Text {
                text: root.subtitle
                visible: !!root.subtitle
                color: Config.styling.text2
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }
        }

        Text {
            text: root.defaultActionLabel
            visible: root.hasActions && text.length > 0 && !switchColumn.visible
            color: Config.styling.text1
            font.pixelSize: 12
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 92
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            id: switchColumn
            visible: root.hasSwitchActions
            spacing: Config.spacing.xxs
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 132
            Layout.preferredWidth: 132
            Layout.maximumWidth: 132

            Item {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: switchControl.implicitWidth
                Layout.preferredHeight: switchControl.implicitHeight

                DashboardToggleSwitch {
                    id: switchControl
                    checked: root.switchState === true
                    anchors.fill: parent
                    onToggled: {
                        if (root.controller)
                            root.controller.activateTreeRowByKey(root.key, "toggle");
                    }
                }
            }
        }
    }

    function selectThisRow() {
        var idx = root.treeView.index(root.row, 0);
        root.treeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
        if (root.controller) {
            root.controller.currentTreeView = root.treeView;
            root.controller.treeVisualRow = root.row;
            root.controller.currentTreeKey = root.key;
            root.controller.activeNodeKey = root.key;
        }
    }

    TapHandler {
        onSingleTapped: {
            root.selectThisRow();
        }
        onDoubleTapped: {
            if (root.controller)
                root.controller.activateTreeRowByKey(root.key, null);
        }
    }
}
