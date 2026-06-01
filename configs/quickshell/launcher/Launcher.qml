import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import "backends" as Backends
import "delegates" as Delegates
import "logic/SearchEngine.js" as SearchEngine
import "logic/EvidenceScorer.js" as EvidenceScorer

PanelWindow {
    id: root

    property alias query: controller.query
    property var shellScreenState: null
    property string backendSet: "all"
    property var backendFilter: null
    property var backendSets: ({
        "all": [backendsBackend, desktopActionsBackend, calculatorBackend, desktopBackend, filesBackend, webBackend],
        "desktop": [desktopBackend],
        "dmenu": [desktopBackend, calculatorBackend, filesBackend]
    })
    readonly property var allBackends: [backendsBackend, desktopActionsBackend, calculatorBackend, desktopBackend, filesBackend, webBackend]
    property var backends: root.backendSets[root.backendSet] || root.backendSets.all
    property Component resultDelegate: defaultResultDelegate
    property Component sectionHeaderDelegate: defaultSectionHeaderDelegate
    property Component actionDelegate
    property bool showSectionHeaders: true
    property bool showSubtitles: true
    property bool showActionHint: true
    property bool showSourceBadge: false
    property bool showTreeResults: true
    property bool showEvidence: false
    property int maxResults: 512
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

    function debugComplete(text) {
        return controller.debugComplete(text || "");
    }

    function debugCompleteBackend(backendName, text) {
        return controller.debugCompleteBackend(backendName || "", text || "");
    }

    function debugRoutes(text) {
        return controller.debugRoutes(text || "");
    }

    function debugSearch(text) {
        return controller.debugSearch(text || "");
    }

    function debugBenchmark(arg) {
        return controller.debugBenchmark(arg || "");
    }

    function debugEvidence(resultId) {
        return controller.debugEvidence(resultId || "");
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
    }

    Backends.WebSearchBackend {
        id: webBackend
        backendId: "web"
        controller: controller
    }

    Backends.FilesBackend {
        id: filesBackend
        backendId: "files"
    }

    LauncherController {
        id: controller
        backends: root.backends
        maxResults: root.maxResults

        onQueryReplacementRequested: function(text) {
            input.text = text;
            updateQuery(text);
            input.forceActiveFocus();
            input.cursorPosition = input.text.length;
        }

        onBackendsChangeRequested: function(backendIds) {
            root.backends = root.allBackends.filter(function(b) {
                return b && backendIds.indexOf(b.backendId) >= 0;
            });
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
                    if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N)) {
                        controller.moveSelection(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P)) {
                        controller.moveSelection(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        if (!(event.modifiers & Qt.ShiftModifier))
                            controller.completeSelected();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (controller.activateSelected(false))
                            root.close();
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
                Layout.preferredHeight: visible ? listView.contentHeight : 0
                Layout.maximumHeight: root.rowHeight * root.visibleResultRows

                onVisibleChanged: { }

                ListView {
                    id: listView
                    anchors.fill: parent
                    model: controller.results
                    currentIndex: controller.selectedIndex
                    clip: true
                    spacing: Config.spacing.xxs
                    interactive: contentHeight > height

                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Loader {
                        id: delegateLoader
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: item ? item.implicitHeight : root.rowHeight
                        sourceComponent: modelData.switchActions
                            ? root.resultDelegate
                            : modelData.children && modelData.children.length > 0 && root.showTreeResults
                            ? root.treeResultDelegate
                            : root.resultDelegate

                        onLoaded: {
                            item.result = modelData;
                            item.selected = Qt.binding(function() { return controller.selectedIndex === index; });
                            item.iconSize = root.iconSize;
                            item.showSubtitle = root.showSubtitles;
                            item.showActionHint = root.showActionHint;
                            item.showSourceBadge = root.showSourceBadge;
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

    Component {
        id: defaultSectionHeaderDelegate
        Delegates.SectionHeader {}
    }

    Component {
        id: treeResultDelegate
        Delegates.TreeResultDelegate {}
    }
}
