import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell.Services.Pipewire
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
    readonly property string effectiveIconName: (root.control && root.control.target === "pipewire" && root.sliderNode)
        ? root.sliderIconName() : root.iconName
    readonly property var effectiveIconColor: (root.control && root.control.target === "pipewire" && root.sliderNode && root.sliderNode.audio)
        ? (root.sliderNode.audio.muted ? Config.styling.critical : Config.styling.secondaryAccent)
        : root.iconColor
    readonly property var switchState: cell(4)
    readonly property bool hasActions: !!cell(5)
    readonly property bool hasSwitchActions: !!cell(6)
    readonly property string defaultActionLabel: cell(7) || ""
    readonly property string key: cell(9) || ""
    readonly property bool lazy: !!cell(11)
    readonly property var control: cell(12) || null
    readonly property bool alwaysExpanded: !!cell(13)
    readonly property var labelMatches: cell(15) || []
    readonly property var subtitleMatches: cell(16) || []
    readonly property bool hasSlider: !!control && control.kind === "slider"
    readonly property var sliderNode: sliderNodeFor(control)
    readonly property real sliderValue: sliderValueFor(control, sliderNode)
    readonly property bool liveSwitchState: switchStateFor(control, sliderNode)
    readonly property bool active: root.controller && root.controller.activeNodeKey === root.key
    readonly property int containedRows: root.hasChildren && root.expanded ? 1 + root.visibleDescendantRows() : 1
    readonly property int depthInset: root.depth * Config.spacing.xs
    readonly property real rowPanelHeight: root.rowHeight - Math.max(Config.spacing.xxs, root.depthGap(root.depth) - Config.spacing.xxs)
    readonly property real rowPanelY: (root.rowHeight - root.rowPanelHeight) / 2
    readonly property real contentInsetY: Config.spacing.xxs

    function cell(column) {
        if (!root.treeView || !root.treeView.model)
            return null;
        return root.treeView.model.data(root.treeView.index(root.row, column), "display");
    }

    function rowDepth(row) {
        if (!root.treeView || !root.treeView.model || row < 0 || row >= root.treeView.rows)
            return -1;
        var idx = root.treeView.index(row, 0);
        var depth = 0;
        var parent = root.treeView.model.parent(idx);
        while (parent && parent.valid) {
            depth += 1;
            parent = root.treeView.model.parent(parent);
        }
        return depth;
    }

    function visibleDescendantRows() {
        if (!root.treeView)
            return 0;
        var count = 0;
        for (var nextRow = root.row + 1; nextRow < root.treeView.rows; nextRow += 1) {
            if (root.rowDepth(nextRow) <= root.depth)
                break;
            count += 1;
        }
        return count;
    }

    function depthGap(depth) {
        return Math.max(Config.spacing.xxs, Config.spacing.xs - depth * 2);
    }

    implicitHeight: root.rowHeight
    z: root.depth

    onCurrentChanged: {
        if (root.current && root.controller) {
            root.controller.currentTreeView = root.treeView;
            root.controller.treeVisualRow = root.row;
            root.controller.currentTreeKey = root.key;
            root.controller.activeNodeKey = root.key;
        }
    }
    color: "transparent"
    border.width: 0

    Rectangle {
        id: depthPanel
        x: root.depthInset
        y: root.rowPanelY
        width: root.width - root.depthInset * 2
        height: root.hasChildren && root.expanded
            ? root.containedRows * root.rowHeight + root.rowPanelY
            : root.rowPanelHeight
        color: root.depth % 2 === 0 ? Config.styling.bg3 : Config.styling.bg4
        border.color: root.active ? Config.styling.primaryAccent : Config.styling.bg5
        border.width: 1
        radius: Config.styling.radius
    }

    Item {
        id: contentFrame
        x: Config.spacing.xs
        y: root.rowPanelY
        width: parent.width - Config.spacing.xs * 2
        height: root.rowPanelHeight

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: root.contentInsetY
            anchors.bottomMargin: root.contentInsetY
            spacing: Config.spacing.sm

            Item {
                implicitWidth: 12
                implicitHeight: 12
                Layout.alignment: Qt.AlignVCenter

                Icon {
                    anchors.fill: parent
                    visible: root.hasChildren
                    iconName: root.expanded ? "pan-down-symbolic" : "pan-end-symbolic"
                    color: Config.styling.text1
                }

                TapHandler {
                    onSingleTapped: {
                        if (!root.hasChildren)
                            return;
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
                visible: !!root.effectiveIconName && root.effectiveIconName !== "system-search"
                iconName: root.effectiveIconName
                fallbackIconName: "system-search"
                color: root.effectiveIconColor
                implicitSize: 20
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: Config.spacing.xxs
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: root.buildHighlightedText(root.title, root.labelMatches)
                    color: Config.styling.text0
                    font.pixelSize: 13
                    font.bold: false
                    textFormat: root.labelMatches.length > 0 ? Text.StyledText : Text.PlainText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                }

                Text {
                    text: root.buildHighlightedText(root.subtitle, root.subtitleMatches)
                    visible: !!root.subtitle
                    color: Config.styling.text2
                    font.pixelSize: 11
                    textFormat: root.subtitleMatches.length > 0 ? Text.StyledText : Text.PlainText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                }
            }

            Text {
                text: root.defaultActionLabel
                visible: root.hasActions && text.length > 0 && !switchColumn.visible && !sliderColumn.visible
                color: Config.styling.text1
                font.pixelSize: 12
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 92
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                id: switchColumn
                visible: root.hasSwitchActions && !sliderColumn.visible
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
                        checked: root.liveSwitchState
                        anchors.fill: parent
                        onToggled: {
                            if (root.controller)
                                root.controller.activateTreeRowByKey(root.key, "toggle");
                        }
                    }
                }
            }

            RowLayout {
                id: sliderColumn
                visible: root.hasSlider
                spacing: Config.spacing.xs
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: 160
                Layout.preferredWidth: 160
                Layout.maximumWidth: 160

                AudioLevelSlider {
                    id: sliderControl
                    from: root.control ? root.control.from || 0 : 0
                    to: root.control ? root.control.to || 100 : 100
                    stepSize: root.control ? root.control.step || 1 : 1
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
        if (control && (control.target === "pipewire-mute" || control.target === "pipewire") && node && node.audio)
            return node.audio.muted === true;
        return root.switchState === true;
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
        if (!root.control || root.control.kind !== "slider")
            return false;
        if (root.control.target === "brightness")
            return Brightness.available;
        return !!(root.sliderNode && root.sliderNode.audio);
    }

    function applySliderValue(value) {
        if (!root.control || root.control.kind !== "slider")
            return;
        if (root.control.target === "brightness") {
            Brightness.setPercent(value);
            return;
        }
        if (root.control.target === "pipewire" && root.sliderNode && root.sliderNode.audio)
            root.sliderNode.audio.volume = Math.max(0, Math.min((root.control.to || 100) / 100, value / 100));
    }

    function buildHighlightedText(text, matches) {
        if (!matches || matches.length === 0 || !text)
            return text || "";
        function escapeHtml(s) {
            return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }
        var sorted = matches.slice().sort(function(a, b) { return a.start - b.start; });
        var merged = [];
        for (var i = 0; i < sorted.length; i++) {
            var r = sorted[i];
            if (r.start >= text.length) break;
            if (r.end <= 0) continue;
            if (!merged.length) {
                merged.push({ start: Math.max(0, r.start), end: Math.min(text.length, r.end) });
            } else {
                var last = merged[merged.length - 1];
                var s = Math.max(0, r.start);
                var e = Math.min(text.length, r.end);
                if (s <= last.end) {
                    last.end = Math.max(last.end, e);
                } else {
                    merged.push({ start: s, end: e });
                }
            }
        }
        var result = "";
        var pos = 0;
        for (var i = 0; i < merged.length; i++) {
            var r = merged[i];
            if (r.start > pos)
                result += escapeHtml(text.substring(pos, r.start));
            result += "<font color=\"" + String(Config.colors.blue) + "\">" + escapeHtml(text.substring(r.start, r.end)) + "</font>";
            pos = r.end;
        }
        if (pos < text.length)
            result += escapeHtml(text.substring(pos));
        return result;
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
