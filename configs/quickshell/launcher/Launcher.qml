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
        visible = true;
        focusGrab.active = true;
        input.forceActiveFocus();
    }

    function close() {
        focusGrab.active = false;
        visible = false;
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

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    visible: false
    focusable: true
    color: "transparent"

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
        width: Math.min(640, Math.max(360, root.width * 0.42))
        height: content.implicitHeight + Config.spacing.sm * 2
        anchors.top: parent.top
        anchors.topMargin: Math.max(Config.spacing.xxl, root.height * 0.16)
        anchors.horizontalCenter: parent.horizontalCenter
        color: Config.styling.bg1
        border.color: Config.styling.bg4
        border.width: 1
        radius: Config.styling.radius

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Config.spacing.sm
            spacing: resultsFrame.visible ? Config.spacing.sm : 0

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
                    if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_N || event.key === Qt.Key_J))) {
                        controller.moveSelection(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_P || event.key === Qt.Key_K))) {
                        controller.moveSelection(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        if (!(event.modifiers & Qt.ShiftModifier))
                            controller.completeSelected();
                        event.accepted = true;
                    } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_H) {
                        if (controller.isInTree())
                            controller.treeCollapseSelected();
                        else
                            controller.toggleCollapseResultTree();
                        event.accepted = true;
                    } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
                        if (controller.isInTree())
                            controller.treeExpandSelected();
                        else
                            controller.toggleExpandResultTree();
                        event.accepted = true;
                    } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_H) {
                        controller.adjustSelectedValue(-1);
                        event.accepted = true;
                    } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_L) {
                        controller.adjustSelectedValue(1);
                        event.accepted = true;
                    } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_M) {
                        controller.toggleSelectedMute();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (event.modifiers & Qt.ShiftModifier && controller.isInTree()) {
                            controller.treeToggleSelected();
                        } else if (controller.activateSelected(false)) {
                            root.close();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        if (text.length > 0) {
                            text = "";
                            controller.reset();
                        } else {
                            root.close();
                        }
                        event.accepted = true;
                    }
                }
            }

            Item {
                id: resultsFrame

                visible: controller.results.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Math.max(resultsList.contentHeight, controller.results.length * root.rowHeight), root.rowHeight * root.visibleResultRows)
                Layout.maximumHeight: root.rowHeight * root.visibleResultRows
                clip: true

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
                    function onResultsChanged() { Qt.callLater(resultsFrame.ensureActiveVisible); }
                }

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    model: controller.results
                    spacing: Config.spacing.xxs
                    reuseItems: false

                    add: Transition {
                        Animations.FadeInAnimation {
                            properties: "opacity"
                            from: 0
                            to: 1
                        }
                        Animations.PropertyAnimation {
                            properties: "y"
                            kind: Animations.PropertyAnimation.Kind.Layout
                        }
                    }

                    remove: Transition {
                        Animations.FadeOutAnimation {
                            properties: "opacity"
                            from: 1
                            to: 0
                        }
                    }

                    displaced: Transition {
                        Animations.PropertyAnimation {
                            properties: "y"
                            kind: Animations.PropertyAnimation.Kind.Layout
                        }
                    }

                    delegate: Loader {
                        id: delegateLoader

                        readonly property var resultData: modelData

                        width: ListView.view ? ListView.view.width : 0
                        height: visible && item ? item.implicitHeight : 0
                        sourceComponent: resultData ? root.resultDelegate : null
                        visible: !!resultData

                        onLoaded: {
                            item.result = Qt.binding(function() { return delegateLoader.resultData; });
                            if ("resultIndex" in item)
                                item.resultIndex = Qt.binding(function() { return index; });
                            item.selected = Qt.binding(function() {
                                return controller.selectedIndex === index;
                            });
                            item.iconSize = Qt.binding(function() { return root.iconSize; });
                            item.showSubtitle = Qt.binding(function() { return root.showSubtitles; });
                            item.showActionHint = root.showActionHint;
                            if ("showEvidence" in item)
                                item.showEvidence = root.showEvidence;
                            if ("controller" in item)
                                item.controller = controller;
                            if (item.activated)
                                item.activated.connect(function(result) {
                                    controller.selectedIndex = index;
                                    if (controller.activateSelected(false))
                                        root.close();
                                });
                        }
                    }
                }
            }
        }
    }

    Component {
        id: defaultResultDelegate
        Delegates.DefaultResultDelegate {}
    }
}
