import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import "backends" as Backends
import "delegates" as Delegates

PanelWindow {
    id: root

    property alias query: controller.query
    property var shellScreenState: null
    property var backends: [backendsBackend, calculatorBackend, desktopBackend, filesBackend, webBackend]
    property Component resultDelegate: defaultResultDelegate
    property Component sectionHeaderDelegate: defaultSectionHeaderDelegate
    property Component actionDelegate
    property bool showSectionHeaders: true
    property bool showSubtitles: true
    property bool showActionHint: true
    property bool showSourceBadge: false
    property int maxResults: 512
    property int maxResultsPerBackend: 5
    property int visibleResultRows: 12
    property int rowHeight: 56
    property int iconSize: 32

    signal closeRequested()

    function open() {
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
    }

    Backends.BackendsBackend {
        id: backendsBackend
        backendId: "backends"
        describedBackends: root.backends
    }

    Backends.CalculatorBackend {
        id: calculatorBackend
        backendId: "calculator"
    }

    Backends.WebSearchBackend {
        id: webBackend
        backendId: "web"
    }

    Backends.FilesBackend {
        id: filesBackend
        backendId: "files"
    }

    LauncherController {
        id: controller
        backends: root.backends
        maxResults: root.maxResults

        onQueryReplacementRequested: text => {
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

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N)) {
                        controller.moveSelection(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P)) {
                        controller.moveSelection(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (controller.activateSelected())
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
                        height: root.rowHeight
                        sourceComponent: root.resultDelegate

                        onLoaded: {
                            item.result = modelData;
                            item.selected = Qt.binding(() => controller.selectedIndex === index);
                            item.iconSize = root.iconSize;
                            item.showSubtitle = root.showSubtitles;
                            item.showActionHint = root.showActionHint;
                            item.showSourceBadge = root.showSourceBadge;
                            if ("controller" in item)
                                item.controller = controller;
                            if (item.activated)
                                item.activated.connect(result => {
                                    controller.selectedIndex = index;
                                    if (controller.activateSelected())
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
}
