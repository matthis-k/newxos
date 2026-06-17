import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.animations as Animations
import qs.services
        import "backends" as Backends
import "delegates" as Delegates
import "visual" as Visual
import "logic/DebugLogger.js" as DebugLogger
import "logic/KeybindPresets.js" as KeybindPresets

PanelWindow {
    id: root

    property alias query: controller.query
    property var shellScreenState: null
    property string backendSet: "all"
    property var backendSets: ({
        "all": [backendsBackend, desktopActionsBackend, calculatorBackend, desktopBackend, filesBackend, webBackend],
        "desktop": [desktopBackend],
        "dmenu": [desktopBackend, calculatorBackend, filesBackend]
    })
    readonly property var allBackends: [backendsBackend, desktopActionsBackend, calculatorBackend, desktopBackend, filesBackend, webBackend]
    property var backends: root.backendSets[root.backendSet] || root.backendSets.all
    property Component resultDelegate: defaultResultDelegate
    property bool showSubtitles: true
    property bool showActionHint: true
    property bool showEvidence: false
    property int maxResultsPerBackend: 5
    property int visibleResultRows: 12
    property int rowHeight: 56
    property int iconSize: 32
    property bool launcherRevealed: false
    property bool closing: false

    function open(arg) {
        if (arg === undefined) {
            root.backends = root.backendSets[root.backendSet] || root.backendSets.all;
        } else if (typeof arg === "string") {
            root.backends = root.backendSets[arg] || root.backendSets.all;
        } else if (Array.isArray(arg)) {
            var first = arg[0];
            if (typeof first === "string")
                root.backends = root.allBackends.filter(function(backend) { return backend && arg.indexOf(backend.backendId) >= 0; });
            else
                root.backends = arg;
        }
        closeTimer.stop();
        closing = false;
        launcherRevealed = false;
        coordinatorAdapter.resetTransientState();
        visible = true;
        if (Config.behaviour.animation.enabled)
            Qt.callLater(function() {
                if (root.visible && !root.closing)
                    root.launcherRevealed = true;
            });
        else
            launcherRevealed = true;
        focusGrab.active = true;
        input.forceActiveFocus();
    }

    function close() {
        if (!root.visible && !closing)
            return;
        if (closing)
            return;

        closing = true;
        focusGrab.active = false;
        launcherRevealed = false;
        if (Config.behaviour.animation.enabled)
            closeTimer.restart();
        else
            finishClose();
    }

    function finishClose() {
        closeTimer.stop();
        visible = false;
        closing = false;
        controller.reset();
        input.text = "";
    }

    function queryPipeline(text) {
        return controller.queryPipeline(text || "");
    }

    function queryPolicies(text) {
        return controller.queryPolicies(text || "");
    }

    function debugBenchmark(arg) {
        return controller.debugBenchmark(arg || "");
    }

    function queryCases() {
        return controller.queryCases();
    }

    function queryRunCases() {
        return controller.queryRunCases();
    }

    function queryVisual(text) {
        return JSON.stringify({
            version: 1,
            type: "visual",
            preview: controller.debugVisualRows(text || ""),
            current: coordinatorAdapter.debugState(root.visualMetrics())
        });
    }

    function queryVisualState() {
        return JSON.stringify({
            version: 1,
            type: "visualState",
            current: coordinatorAdapter.debugState(root.visualMetrics())
        });
    }

    function queryVisualApply(text) {
        const preview = controller.debugApplyQuery(text || "");
        return JSON.stringify({
            version: 1,
            type: "visualApply",
            preview: preview,
            current: coordinatorAdapter.debugState(root.visualMetrics())
        });
    }

    function queryVisualDebug(arg) {
        const value = String(arg === undefined ? "" : arg).toLowerCase();
        transitionCoordinator.debugEnabled = value === "1" || value === "true" || value === "on" || value === "yes";
        return root.queryVisualState();
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    visible: false
    focusable: true
    color: "transparent"

    Timer {
        id: closeTimer

        interval: Config.motion.medium
        repeat: false
        onTriggered: root.finishClose()
    }

    Component.onCompleted: {
        if (WlrLayershell)
            WlrLayershell.layer = WlrLayer.Overlay;
        controller.resultView = resultViewAdapter;
    }

    QtObject {
        id: resultViewAdapter

        function itemAt(index) {
            return resultsList.itemAtIndex(index);
        }
    }

    Visual.LauncherCoordinatorAdapter {
        id: coordinatorAdapter
        controller: controller
        coordinator: transitionCoordinator
    }

    Animations.TransitionListCoordinator {
        id: transitionCoordinator
    }

    function visualContextKey() {
        return (root.backends || []).map(function(backend) {
            return backend ? backend.backendId || "" : "";
        }).join("|");
    }

    function applyVisualSnapshot() {
        coordinatorAdapter.applySnapshot({
            inputText: controller.query,
            contextKey: root.visualContextKey(),
            reason: "query"
        });
    }

    function visualMetrics() {
        const items = [];
        if (resultsList) {
            for (let i = 0; i < resultsList.count; i += 1) {
                const delegate = resultsList.itemAtIndex(i);
                items.push({
                    index: i,
                    y: delegate ? delegate.y : null,
                    height: delegate ? delegate.height : null,
                    fullHeight: delegate ? delegate.fullHeight : null,
                    reveal: delegate ? delegate.reveal : null,
                    phase: delegate ? delegate.phase : "",
                    key: delegate ? delegate.key : ""
                });
            }
        }
        return {
            query: controller.query || "",
            resultsCount: controller.results.length,
            selectedIndex: controller.selectedIndex,
            cardHeight: card ? card.height : 0,
            frameHeight: resultsFrame ? resultsFrame.height : 0,
            frameTargetHeight: resultsFrame ? resultsFrame.targetHeight : 0,
            listHeight: resultsList ? resultsList.height : 0,
            listContentHeight: resultsList ? resultsList.contentHeight : 0,
            listContentY: resultsList ? resultsList.contentY : 0,
            items: items
        };
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: {
            if (root.visible)
                root.close();
        }
    }

    Backends.DesktopAppsBackend {
        id: desktopBackend
        backendId: "desktop"
        maxResults: root.maxResultsPerBackend
        controller: controller
    }

    Backends.BackendsBackend {
        id: backendsBackend
        backendId: "backends"
        describedBackends: root.allBackends
        controller: controller
    }

    Backends.DesktopActionsBackend {
        id: desktopActionsBackend
        shellScreenState: root.shellScreenState
        controller: controller
    }

    Backends.CalculatorBackend {
        id: calculatorBackend
        backendId: "calculator"
        controller: controller
    }

    Backends.WebSearchBackend {
        id: webBackend
        backendId: "web"
        controller: controller
    }

    Backends.FilesBackend {
        id: filesBackend
        backendId: "files"
        controller: controller
    }

    LauncherController {
        id: controller
        backends: root.backends
        maxResults: root.visibleResultRows

        onQueryReplacementRequested: function(text) {
            input.text = text;
            updateQuery(text);
            input.forceActiveFocus();
            input.cursorPosition = input.text.length;
        }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        property real revealOffset: root.launcherRevealed ? 0 : -Config.spacing.sm

        width: Math.min(640, Math.max(360, root.width * 0.42))
        height: content.implicitHeight + Config.spacing.sm * 2
        opacity: root.launcherRevealed ? 1 : 0
        anchors.top: parent.top
        anchors.topMargin: Math.max(Config.spacing.xxl, root.height * 0.16) + revealOffset
        anchors.horizontalCenter: parent.horizontalCenter
        color: Config.styling.bg1
        border.color: Config.styling.bg4
        border.width: 1
        radius: Config.styling.radius
        clip: true

        Animations.PanelBehavior on opacity {
        }

        Animations.PanelBehavior on revealOffset {
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Config.spacing.sm
            height: implicitHeight
            spacing: resultsFrame.visible ? Config.spacing.sm : 0

            Animations.LayoutBehavior on spacing {
            }

            TextField {
                id: input
                placeholderText: qsTr("Search apps, ? for sources")
                text: controller.query
                color: Config.styling.text0
                placeholderTextColor: Config.styling.placeholderText
                selectedTextColor: Config.styling.selectionText
                selectionColor: Config.styling.selectionBackgroundActive
                font.pixelSize: 18
                focus: root.visible
                Layout.fillWidth: true
                Layout.preferredHeight: 32

                background: Rectangle {
                    color: Config.styling.bg2
                    border.color: input.activeFocus ? Config.styling.primaryAccent : Config.styling.bg4
                    border.width: 1
                    radius: Config.styling.radius
                }

                onTextEdited: controller.updateQuery(text)

                Keys.onPressed: function(event) {
                    if (!handleLauncherKey(event))
                        return;
                    event.accepted = true;
                }

                function handleLauncherKey(event) {
                    DebugLogger.log("key", "pressed", {
                        key: event.key,
                        text: event.text,
                        modifiers: event.modifiers,
                        activeNodeKey: controller.activeNodeKey,
                        currentTreeKey: controller.currentTreeKey,
                        selectedIndex: controller.selectedIndex,
                        queryLength: text.length
                    });

                    if (event.key === Qt.Key_Escape)
                        return handleEscapeKey(event);

                    if (event.modifiers & Qt.AltModifier) {
                        var target = controller.selectedActionTarget();
                        var action = KeybindPresets.altActionForKey(target, event.key);
                        if (action) {
                            if (action === "switch-on" || action === "slider-inc")
                                { controller.adjustSelectedValue(1); return true; }
                            if (action === "switch-off" || action === "slider-dec")
                                { controller.adjustSelectedValue(-1); return true; }
                            if (action === "switch-toggle")
                                { controller.toggleSelectedMute(); return true; }
                        }
                        return handleAltInteractionKey(event);
                    }

                    if (event.modifiers & Qt.ControlModifier)
                        return handleCtrlKey(event);

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        return handleActivationKey(event);

                    if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))
                        return handleTabKey(event);

                    return false;
                }

                function handleEscapeKey(event) {
                    if (text.length > 0) {
                        text = "";
                        controller.reset();
                    } else {
                        root.close();
                    }
                    return true;
                }

                function handleActivationKey(event) {
                    if (event.modifiers & Qt.ShiftModifier && controller.isInTree()) {
                        controller.treeToggleSelected();
                        return true;
                    }

                    var target = controller.selectedActionTarget();
                    DebugLogger.log("activate", "enter", {
                        targetId: target ? target.id || target.nodeId || "" : "none",
                        targetKind: target ? target.kind || "" : "",
                        inTree: controller.isInTree()
                    });

                    var result = controller._handleActivationWithConfirm();
                    DebugLogger.log("activate", "result", {
                        closeRequested: result ? result.closeRequested : false,
                        close: result ? result.close : false
                    });
                    if (result && result.close !== false && result.closeRequested)
                        root.close();
                    return true;
                }

                function handleTabKey(event) {
                    var result = controller.runRecipeSlot("complete");
                    return true;
                }

                function handleCtrlKey(event) {
                    switch (event.key) {
                    case Qt.Key_Down:
                    case Qt.Key_N:
                    case Qt.Key_J:
                        controller.moveSelection(1);
                        return true;
                    case Qt.Key_Up:
                    case Qt.Key_P:
                    case Qt.Key_K:
                        controller.moveSelection(-1);
                        return true;
                    case Qt.Key_H:
                        if (controller.isInTree())
                            controller.treeCollapseSelected();
                        else
                            controller.toggleCollapseResultTree();
                        return true;
                    case Qt.Key_L:
                        if (controller.isInTree())
                            controller.treeExpandSelected();
                        else
                            controller.toggleExpandResultTree();
                        return true;
                    }
                    return false;
                }

                function handleAltInteractionKey(event) {
                    var keyName = keyNameFromEvent(event);
                    if (!keyName)
                        return false;

                    var target = controller.selectedActionTarget();
                    DebugLogger.log("alt-interaction", "dispatch", {
                        keyName: keyName,
                        targetId: target ? target.id || target.nodeId || "" : "none",
                        targetKind: target ? target.kind || "" : "",
                        availableKeys: target ? Object.keys(RecipeResolver.effectiveInteractions(target)) : []
                    });

                    var result = controller.runInteractionForKey(keyName);
                    DebugLogger.log("alt-interaction", "result", {
                        keyName: keyName,
                        close: result ? result.close : false,
                        success: result ? result.success : false
                    });
                    return true;
                }

                function keyNameFromEvent(event) {
                    var map = {};
                    map[String(Qt.Key_H)] = "h";
                    map[String(Qt.Key_L)] = "l";
                    map[String(Qt.Key_M)] = "m";
                    map[String(Qt.Key_J)] = "j";
                    map[String(Qt.Key_K)] = "k";

                    var lower = String.fromCharCode(event.key).toLowerCase();
                    if (lower.length === 1)
                        return lower;

                    return map[String(event.key)] || lower;
                }
            }

            Item {
                id: resultsFrame
                readonly property real targetHeight: {
                    const contentHeight = resultsList.contentHeight || 0;
                    const bootstrapHeight = transitionCoordinator.hasActiveItems ? root.rowHeight : 0;
                    return Math.min(Math.max(contentHeight, bootstrapHeight), root.rowHeight * root.visibleResultRows);
                }

                visible: targetHeight > 0 || resultsList.contentHeight > 0
                clip: true
                Layout.fillWidth: true
                Layout.preferredHeight: targetHeight
                Layout.maximumHeight: root.rowHeight * root.visibleResultRows

                function ensureActiveVisible() {
                    if (controller.selectedIndex < 0 || controller.selectedIndex >= resultsList.count)
                        return;
                    var current = resultsList.itemAtIndex(controller.selectedIndex);
                    var y = current ? current.y : controller.selectedIndex * (root.rowHeight + resultsList.spacing);
                    var height = current ? current.height : root.rowHeight;
                    if (controller.isInTree()) {
                        var treeRowH = 44;
                        if (current && current.item && current.item.treeRowHeight)
                            treeRowH = current.item.treeRowHeight;
                        y += root.rowHeight + resultsList.spacing + Math.max(0, controller.treeVisualRow) * treeRowH;
                        height = treeRowH;
                    }
                    if (y < resultsList.contentY)
                        resultsList.contentY = y;
                    else if (y + height > resultsList.contentY + resultsList.height)
                        resultsList.contentY = Math.max(0, y + height - resultsList.height);
                }

                Connections {
                    target: controller
                    function onActiveNodeKeyChanged() { Qt.callLater(resultsFrame.ensureActiveVisible); }
                    function onTreeVisualRowChanged() { Qt.callLater(resultsFrame.ensureActiveVisible); }
                    function onResultsChanged() {
                        root.applyVisualSnapshot();
                        Qt.callLater(resultsFrame.ensureActiveVisible);
                    }
                }

                Visual.LauncherResultList {
                    id: resultsList
                    anchors.fill: parent
                    coordinator: transitionCoordinator
                    resultDelegate: root.resultDelegate
                    controller: controller
                    iconSize: root.iconSize
                    visibleResultRows: root.visibleResultRows
                    showSubtitles: root.showSubtitles
                    showActionHint: root.showActionHint
                    showEvidence: root.showEvidence
                    rowSpacing: Config.spacing.xxs
                    estimatedRowHeight: root.rowHeight

                    onCloseRequested: root.close()
                }
            }
        }
    }

    Component {
        id: defaultResultDelegate
        Delegates.DefaultResultDelegate {}
    }
}
