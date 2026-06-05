import QtQuick
import QtQuick.Layouts
import Qt.labs.qmlmodels
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
    property int resultIndex: -1
    property alias treeView: childTreeView
    readonly property int switchControlWidth: 132
    readonly property int switchActionButtonWidth: 40
    property int treeRowHeight: 40

    readonly property var defaultAction: {
        var actions = result.actions || [];
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i].default) return actions[i];
        }
        return actions[0] || null;
    }
    readonly property int childCount: (result.children || []).length
    readonly property bool hasTreeChildren: childCount > 0
    property int _expandedOverride: 0 // 0=use policy, 1=force collapse, 2=force expand
    property bool expanded: _expandedOverride === 1 ? false : (_expandedOverride === 2 ? true : (result.alwaysExpanded !== false && hasTreeChildren))
    signal activated(var result)

    Component.onCompleted: syncControllerTreeView()

    onControllerChanged: syncControllerTreeView()
    onResultChanged: { _expandedOverride = 0; syncControllerTreeView(); }
    onSelectedChanged: syncControllerTreeView()
    onTreeModelDataChanged: reloadTreeModel()

    function collapseTree() { _expandedOverride = 1; }
    function expandTree() { _expandedOverride = 2; }

    Connections {
        target: root.controller
        function onCollapseResultExpanded(index) { if (index === root.resultIndex) root.collapseTree(); }
        function onExpandResultExpanded(index) { if (index === root.resultIndex) root.expandTree(); }
        function onTreeSwitchRefreshRequested(index) { if (index === root.resultIndex) root.reloadTreeModel(); }
    }

    function syncControllerTreeView() {
        if (controller && root.resultIndex >= 0 && root.treeView)
            controller.registerResultTreeView(root.resultIndex, root.treeView);
    }

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
                iconName: root.hasTreeChildren ? (root.expanded ? "pan-down-symbolic" : "pan-end-symbolic") : ""
                fallbackIconName: "pan-end-symbolic"
                visible: root.hasTreeChildren
                color: root.hasTreeChildren ? Config.styling.text1 : Config.styling.bg4
                implicitSize: 12
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
            }

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
                                color: Config.styling.text2
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
                visible: root.hasSwitchActions(root.result)
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
                        onToggled: {
                            if (root.controller)
                                root.controller.activateResultAction(root.result, "toggle");
                        }
                    }
                }

            }
        }

        ColumnLayout {
            visible: root.expanded && root.hasTreeChildren
            Layout.fillWidth: true
            spacing: Config.spacing.xxs

                TreeView {
                    id: childTreeView
                    visible: treeModel.rows && treeModel.rows.length > 0
                    interactive: false
                    keyNavigationEnabled: false
                    clip: false
                    selectionModel: ItemSelectionModel {}
                    Layout.fillWidth: true
                    implicitHeight: rows * root.treeRowHeight
                    columnWidthProvider: function(column) { return column === 0 ? width : 0; }

                    onWidthChanged: forceLayout()

                    model: TreeModel {
                        id: treeModel

                        TableModelColumn { display: "title" }
                        TableModelColumn { display: "subtitle" }
                        TableModelColumn { display: "icon" }
                        TableModelColumn { display: "iconColor" }
                        TableModelColumn { display: "switchState" }
                        TableModelColumn { display: "hasActions" }
                        TableModelColumn { display: "hasSwitchActions" }
                        TableModelColumn { display: "defaultActionLabel" }
                        TableModelColumn { display: "executable" }
                        TableModelColumn { display: "key" }
                        TableModelColumn { display: "filterable" }
                        TableModelColumn { display: "lazy" }

                        rows: []

                        Component.onCompleted: root.reloadTreeModel()
                    }

                delegate: TreeRowDelegate {
                    controller: root.controller
                    rowHeight: root.treeRowHeight
                }

                onExpanded: function(row, depth) {
                }
            }

            Item {
                visible: !(treeModel.rows && treeModel.rows.length > 0) && root.hasTreeChildren
                Layout.preferredHeight: root.treeRowHeight
                Layout.fillWidth: true

                Text {
                    anchors.centerIn: parent
                    text: qsTr("No matching children")
                    color: Config.styling.text2
                    font.pixelSize: 11
                }
            }
        }
    }

    readonly property var treeModelData: root.buildTreeRows(root.result.children || [])

    function reloadTreeModel() {
        if (!treeModel)
            return;
        treeModel.clear();
        var rows = root.treeModelData || [];
        for (var i = 0; i < rows.length; i += 1)
            treeModel.appendRow(rows[i]);
    }

    function defaultActionLabelFor(row) {
        if (!row || !row.actions) return "";
        for (var i = 0; i < row.actions.length; i += 1) {
            if (row.actions[i].default) return row.actions[i].label || "";
        }
        return row.actions.length > 0 ? (row.actions[0].label || "") : "";
    }

    function buildTreeRows(children) {
        if (!children || !children.length) return [];
        var out = [];
        for (var i = 0; i < children.length; i += 1) {
            var child = children[i];
            var treeRow = {
                title: child.title || "",
                subtitle: child.subtitle || "",
                icon: child.icon || "",
                iconColor: child.iconColor || "",
                switchState: child.switchState === undefined ? null : child.switchState,
                hasActions: !!(child.actions && child.actions.length > 0),
                hasSwitchActions: !!root.hasSwitchActions(child),
                defaultActionLabel: root.defaultActionLabelFor(child),
                executable: !!child.executable,
                key: child.id || child.nodeId || String(i),
                filterable: !!child.filterable,
                lazy: !!child.lazy
            };
            if (child.children && child.children.length > 0)
                treeRow.rows = root.buildTreeRows(child.children);
            else if (child.lazy)
                treeRow.rows = [];
            out.push(treeRow);
        }
        return out;
    }

    function hasSwitchActions(row) {
        if (!row)
            return false;
        if (row.switchActions && (row.switchActions.on || row.switchActions.off || row.switchActions.toggle))
            return true;
        if (row.switchState === null || row.switchState === undefined)
            return false;
        var actions = row.actions || [];
        return actions.some(function(action) { return action && (action.id === "on" || action.id === "off" || action.id === "toggle"); });
    }

    function hasSwitchAction(row, actionId) {
        if (!row)
            return false;
        if (row.switchActions && row.switchActions[actionId])
            return true;
        var actions = row.actions || [];
        return actions.some(function(action) { return action && action.id === actionId; });
    }

    function defaultActionFor(row) {
        var actions = row && row.actions || [];
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i].default) return actions[i];
        }
        return actions[0] || null;
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
