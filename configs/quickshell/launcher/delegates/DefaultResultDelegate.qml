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
    property int treeLevel: 0
    readonly property int switchControlWidth: 132
    readonly property int switchActionButtonWidth: 40

    readonly property var defaultAction: {
        var actions = result.actions || [];
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i].default) return actions[i];
        }
        return actions[0] || null;
    }
    readonly property int childCount: root.result.filterable ? root.filteredChildren.length : (result.children || []).length
    readonly property bool hasTreeChildren: childCount > 0
    readonly property bool selectedChildActive: root.treeLevel === 0 && controller && controller.childIndex >= 0
    function findWordBoundaryMatch(text, token, startFrom) {
        if (startFrom === undefined) startFrom = 0;
        var idx = startFrom;
        while ((idx = text.indexOf(token, idx)) >= 0) {
            if (idx === 0) return idx;
            var prev = text[idx - 1];
            if (prev === " " || prev === "-" || prev === "_") return idx;
            idx += 1;
        }
        return -1;
    }

    readonly property var filteredChildren: {
        if (!root.result.filterable || !root.controller || !root.controller.query)
            return root.result.children || [];
        var q = root.controller.query.trim().toLowerCase();
        if (!q)
            return root.result.children || [];
        var tokens = q.split(/\s+/).filter(Boolean);
        var parentTitle = (root.result.title || "").toLowerCase();
        var consumedParentPos = {};
        var consumedChildIdx = {};
        var children = root.result.children || [];

        for (var ti = 0; ti < tokens.length; ti += 1) {
            var t = tokens[ti];
            var matched = false;

            // 1. Try parent word-boundary regions (depth 0)
            var searchPos = 0;
            while (!matched) {
                var pos = root.findWordBoundaryMatch(parentTitle, t, searchPos);
                if (pos < 0) break;
                if (!consumedParentPos[pos]) {
                    consumedParentPos[pos] = true;
                    matched = true;
                    break;
                }
                searchPos = pos + 1;
            }
            if (matched) continue;

            // 2. Try child word-boundary regions (depth 1). Siblings are separate paths,
            // so multiple children may consume the same token.
            for (var ci = 0; ci < children.length; ci += 1) {
                var childText = ((children[ci].title || "") + " " + (children[ci].subtitle || "")).toLowerCase();
                if (root.findWordBoundaryMatch(childText, t) >= 0) {
                    consumedChildIdx[String(ci)] = true;
                    matched = true;
                }
            }
        }

        var hasChildMatch = false;
        for (var ck in consumedChildIdx) { hasChildMatch = true; break; }
        if (hasChildMatch) {
            var keep = consumedChildIdx;
            return children.filter(function(c, idx) { return keep[String(idx)]; });
        }
        return children;
    }
    property bool expanded: result.alwaysExpanded !== false ? hasTreeChildren : (selected && hasTreeChildren)

    signal activated(var result)

    implicitHeight: Math.max(56, mainLayout.implicitHeight + Config.spacing.xs * 2)
    color: selected && !selectedChildActive ? Config.styling.selectionBackgroundActive : Config.styling.bg2
    border.color: selected && !selectedChildActive ? Config.styling.primaryAccent : Config.styling.bg4
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
                            visible: root.hasSwitchAction(root.result, modelData.id)
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

        ColumnLayout {
            visible: root.expanded && root.hasTreeChildren
            Layout.fillWidth: true
            Layout.leftMargin: Math.min(40, Config.spacing.md + root.treeLevel * Config.spacing.sm)
            spacing: Config.spacing.xxs

            Repeater {
                model: root.result.filterable ? root.filteredChildren : (root.result.children || [])

                Rectangle {
                    readonly property var childRow: modelData
                    readonly property bool childSelected: root.selected && root.controller && root.controller.childIndex === index
                    readonly property var childDefaultAction: root.defaultActionFor(childRow)

                    color: childSelected ? Config.styling.selectionBackgroundActive : Config.styling.bg3
                    border.color: childSelected ? Config.styling.primaryAccent : Config.styling.bg4
                    border.width: 1
                    radius: Config.styling.radius
                    Layout.fillWidth: true
                    implicitHeight: childLayout.implicitHeight + Config.spacing.xs * 2

                    RowLayout {
                        id: childLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Config.spacing.xs
                        spacing: Config.spacing.sm

                        Icon {
                            iconName: modelData.children && modelData.children.length > 0 ? "pan-end-symbolic" : ""
                            fallbackIconName: "pan-end-symbolic"
                            visible: modelData.children && modelData.children.length > 0
                            color: modelData.children && modelData.children.length > 0 ? Config.styling.text1 : Config.styling.bg4
                            implicitSize: 12
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                        }

                        Icon {
                            iconName: modelData.icon || root.result.icon || "application-x-executable"
                            fallbackIconName: "application-x-executable"
                            color: modelData.iconColor || root.result.iconColor || undefined
                            implicitSize: 20
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }

                        ColumnLayout {
                            spacing: Config.spacing.xxs
                            Layout.fillWidth: true

                            Text {
                                text: modelData.breadcrumbText || modelData.title || ""
                                color: Config.styling.text1
                                font.pixelSize: 13
                                font.bold: childSelected
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
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: root.showActionHint && childDefaultAction && !root.hasSwitchActions(modelData) ? childDefaultAction.label : ""
                            visible: text.length > 0
                            color: Config.styling.text1
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 92
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            visible: root.hasSwitchActions(modelData)
                            spacing: Config.spacing.xxs
                            Layout.alignment: Qt.AlignVCenter
                            Layout.minimumWidth: root.switchControlWidth
                            Layout.preferredWidth: root.switchControlWidth
                            Layout.maximumWidth: root.switchControlWidth

                            Item {
                                Layout.alignment: Qt.AlignRight
                                Layout.preferredWidth: childSwitchControl.implicitWidth
                                Layout.preferredHeight: childSwitchControl.implicitHeight

                                DashboardToggleSwitch {
                                    id: childSwitchControl
                                    checked: modelData.switchState === true
                                    anchors.fill: parent
                                    onToggled: {
                                        if (root.controller)
                                            root.controller.activateResultAction(modelData, "toggle");
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
                                        visible: root.hasSwitchAction(childRow, modelData.id)
                                        color: childDefaultAction && childDefaultAction.id === modelData.id ? Config.colorWithOpacity(Config.styling.primaryAccent, 0.25) : Config.styling.bg3
                                        border.color: childDefaultAction && childDefaultAction.id === modelData.id ? Config.styling.primaryAccent : Config.styling.bg4
                                        border.width: 1
                                        radius: Config.styling.radius
                                        Layout.preferredWidth: root.switchActionButtonWidth
                                        Layout.preferredHeight: 20

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: Config.styling.text1
                                            font.pixelSize: 10
                                            font.bold: childDefaultAction && childDefaultAction.id === modelData.id
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: function(mouse) {
                                                mouse.accepted = true;
                                                if (root.controller)
                                                    root.controller.activateResultAction(childRow, modelData.id);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    TapHandler {
                        onSingleTapped: {
                            if (root.controller)
                                root.controller.applyIntent(modelData, modelData.enter);
                        }
                    }
                }
            }
        }
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
