import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell.Services.Pipewire
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
    property int treeRowHeight: 44
    readonly property bool hasSlider: !!result.control && result.control.kind === "slider"
    readonly property var sliderNode: sliderNodeFor(result.control)
    readonly property real sliderValue: sliderValueFor(result.control, sliderNode)
    readonly property bool liveSwitchState: switchStateFor(result.control, sliderNode)

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
    onResultChanged: { _expandedOverride = 0; syncControllerTreeView(); reloadTreeModel(); }
    onSelectedChanged: syncControllerTreeView()

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
                                color: Config.styling.text2
                                implicitSize: 12
                                Layout.preferredWidth: 12
                                Layout.preferredHeight: 12
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
                visible: text.length > 0 && !switchColumn.visible && !sliderColumn.visible
                color: Config.styling.text1
                font.pixelSize: 12
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 92
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                id: switchColumn
                visible: root.hasSwitchActions(root.result) && !sliderColumn.visible
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
                        checked: root.liveSwitchState
                        anchors.fill: parent
                        onToggled: {
                            if (root.controller)
                                root.controller.activateResultAction(root.result, "toggle");
                        }
                    }
                }

            }

            RowLayout {
                id: sliderColumn
                visible: root.hasSlider
                spacing: Config.spacing.xs
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: 180
                Layout.preferredWidth: 180
                Layout.maximumWidth: 180

                AudioLevelSlider {
                    id: resultSliderControl
                    from: root.result.control ? root.result.control.from || 0 : 0
                    to: root.result.control ? root.result.control.to || 100 : 100
                    stepSize: root.result.control ? root.result.control.step || 1 : 1
                    value: root.sliderValue
                    valueText: Math.round(root.sliderValue) + "%"
                    showIcon: false
                    iconName: root.sliderIconName()
                    iconColor: root.sliderNode && root.sliderNode.audio && root.sliderNode.audio.muted ? Config.styling.critical : Config.styling.text0
                    accentColor: root.sliderNode && root.sliderNode.audio && root.sliderNode.audio.muted ? Config.styling.critical : Config.colors.blue
                    valueTextWidth: 34
                    iconSize: 18
                    enabled: root.sliderEnabled()
                    Layout.fillWidth: true
                    onIconClicked: {
                        if (root.sliderNode && root.sliderNode.audio)
                            root.sliderNode.audio.muted = !root.sliderNode.audio.muted;
                    }
                    onValueModified: root.applySliderValue(value)
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
                    implicitHeight: rows * root.treeRowHeight + Config.spacing.xs
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
                        TableModelColumn { display: "control" }
                        TableModelColumn { display: "alwaysExpanded" }
                        TableModelColumn { display: "presentation" }

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

    function reloadTreeModel() {
        if (!treeModel)
            return;
        treeModel.rows = root.buildTreeRows(root.result.children || []);
        Qt.callLater(root.expandDefaultTreeRows);
    }

    function expandDefaultTreeRows() {
        if (!childTreeView || !treeModel)
            return;
        var changed = true;
        while (changed) {
            changed = false;
            for (var row = 0; row < childTreeView.rows; row += 1) {
                var idx = childTreeView.index(row, 0);
                if (!idx.valid || childTreeView.isExpanded(row))
                    continue;
                var policyIdx = childTreeView.index(row, 13);
                if (treeModel.data(policyIdx, "display") && treeModel.hasChildren(idx)) {
                    childTreeView.expand(row);
                    changed = true;
                }
            }
        }
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
                switchState: child.switchState === true,
                hasActions: !!(child.actions && child.actions.length > 0),
                hasSwitchActions: !!root.hasSwitchActions(child),
                defaultActionLabel: root.defaultActionLabelFor(child),
                executable: !!child.executable,
                key: child.id || child.nodeId || String(i),
                filterable: !!child.filterable,
                lazy: !!child.lazy,
                control: null,
                alwaysExpanded: child.alwaysExpanded === true,
                presentation: child.presentation || null
            };
            if (child.control)
                treeRow.control = child.control;
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

    function sliderNodeFor(control) {
        if (!control || (control.target !== "pipewire" && control.target !== "pipewire-mute"))
            return null;
        for (const node of Pipewire.nodes.values || []) {
            if (String(node.id) === String(control.nodeId))
                return node;
        }
        return null;
    }

    function switchStateFor(control, node) {
        if (control && control.kind === "switch" && control.target === "pipewire-mute" && node && node.audio)
            return node.audio.muted === true;
        return root.result.switchState === true;
    }

    function sliderIconName() {
        if (!root.sliderNode || !root.sliderNode.audio)
            return "audio-volume-muted-symbolic";
        if (root.sliderNode.audio.muted)
            return "audio-volume-muted-symbolic";
        var vol = root.sliderNode.audio.volume || 0;
        if (vol <= 0.001)
            return "audio-volume-muted-symbolic";
        if (vol < 0.34)
            return "audio-volume-low-symbolic";
        if (vol < 0.67)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function sliderValueFor(control, node) {
        if (!control || control.kind !== "slider")
            return 0;
        if (control.target === "brightness")
            return Brightness.percent;
        if (control.target === "pipewire" && node && node.audio)
            return Math.round((node.audio.volume || 0) * 100);
        return control.value || 0;
    }

    function sliderEnabled() {
        if (!root.result.control || root.result.control.kind !== "slider")
            return false;
        if (root.result.control.target === "brightness")
            return Brightness.available;
        return !!(root.sliderNode && root.sliderNode.audio);
    }

    function applySliderValue(value) {
        var control = root.result.control;
        if (!control || control.kind !== "slider")
            return;
        if (control.target === "brightness") {
            Brightness.setPercent(value);
            return;
        }
        if (control.target === "pipewire" && root.sliderNode && root.sliderNode.audio)
            root.sliderNode.audio.volume = Math.max(0, Math.min((control.to || 100) / 100, value / 100));
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
