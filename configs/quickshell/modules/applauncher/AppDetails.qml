import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.utils
import "."

Item {
    id: root
    focus: true

    required property DesktopEntry desktopEntry
    required property var view

    property int pad: Pixels.mm(4, screen)
    property int gap: Pixels.mm(6, screen)
    property int lineGap: Pixels.mm(2, screen)
    property int titlePx: Pixels.mm(6, screen)
    property int bodyPx: Pixels.mm(4.5, screen)
    property int monoPx: Pixels.mm(4.5, screen)
    property int iconSize: Pixels.mm(14, screen)
    property real actionIconScale: 0.7
    property int selectedIndex: 0

    readonly property var actionList: desktopEntry ? (desktopEntry.actions ? Array.prototype.slice.call(desktopEntry.actions) : []).sort((a, b) => {
        const nameA = a && a.name ? a.name : "";
        const nameB = b && b.name ? b.name : "";
        return nameA.localeCompare(nameB);
    }) : []
    readonly property int maxSelectedIndex: Math.max(0, actionList.length)
    readonly property var detailsRows: [
        {
            label: "Comment",
            value: desktopEntry.comment || ""
        },
        {
            label: "Categories",
            value: (desktopEntry.categories || []).join(", ")
        },
        {
            label: "Keywords",
            value: (desktopEntry.keywords || []).join(", ")
        },
        {
            label: "Run In Terminal",
            value: desktopEntry.runInTerminal ? "Yes" : "No"
        }
    ].filter(row => row.value && row.value.length)

    function clampSelection() {
        selectedIndex = Math.max(0, Math.min(selectedIndex, maxSelectedIndex));
    }

    function cycleSelection(delta) {
        const count = maxSelectedIndex + 1;
        if (!count)
            return;
        let next = selectedIndex + delta;
        next = ((next % count) + count) % count;
        selectedIndex = next;
    }

    function executeSelected(index) {
        if (index === 0) {
            desktopEntry.execute();
        } else {
            actionList[index - 1].execute();
        }
        if (view && view.closeDetails)
            view.closeDetails();
    }

    implicitWidth: Math.min(view ? view.get("appsearch").implicitWidth : screen.width * 0.6, contentBackground.implicitWidth)
    implicitHeight: Math.min(view ? view.get("appsearch").implicitHeight : screen.height * 0.7, contentBackground.implicitHeight)

    Rectangle {
        anchors.fill: parent
        color: Config.styling.bg0
        border.width: 1
        border.color: Config.styling.primaryAccent
    }

    Item {
        id: contentBackground
        anchors.fill: parent
        implicitWidth: Math.max(contentColumn.implicitWidth + 2 * root.pad, Pixels.mm(120, screen))
        implicitHeight: contentColumn.implicitHeight + 2 * root.pad

        Flickable {
            anchors.fill: parent
            anchors.margins: root.pad
            clip: true
            contentWidth: width
            contentHeight: contentColumn.implicitHeight

            Column {
                id: contentColumn
                width: parent.width
                spacing: root.gap

                Item {
                    id: headerRow
                    width: parent.width
                    implicitHeight: headerLayout.implicitHeight

                    HoverHandler {
                        id: headerHover
                    }
                    TapHandler {
                        target: headerRow
                        onTapped: {
                            root.selectedIndex = 0;
                            root.executeSelected(0);
                        }
                    }

                    ActiveIndicator {
                        anchors.fill: parent
                        side: ActiveIndicator.Side.Left
                        animationMode: ActiveIndicator.AnimationMode.GrowAll
                        thickness: Pixels.mm(1.5, screen)
                        bgActive: headerHover.hovered || root.selectedIndex === 0
                        active: root.selectedIndex === 0
                    }

                    Item {
                        id: headerLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: root.pad
                        anchors.rightMargin: root.pad
                        implicitHeight: Math.max(root.iconSize, titleColumn.implicitHeight)
                        height: implicitHeight

                        Icon {
                            id: appIcon
                            width: root.iconSize
                            height: root.iconSize
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            iconName: desktopEntry ? desktopEntry.icon : ""
                        }

                        Column {
                            id: titleColumn
                            anchors.left: appIcon.right
                            anchors.leftMargin: root.lineGap
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.lineGap

                            Text {
                                text: desktopEntry ? desktopEntry.name : ""
                                color: Config.styling.text0
                                font.pixelSize: root.titlePx
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: (desktopEntry && desktopEntry.genericName) ? desktopEntry.genericName : ""
                                visible: text.length > 0
                                color: Config.styling.text2
                                font.pixelSize: root.bodyPx
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: root.lineGap

                    Text {
                        text: "Executable"
                        color: Config.styling.text0
                        font.pixelSize: root.titlePx
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: parent.width
                        color: Config.styling.bg1 || Config.styling.bg0
                        border.width: 1
                        border.color: Config.styling.bg4
                        implicitHeight: execText.implicitHeight + 2 * root.pad

                        Text {
                            id: execText
                            anchors.fill: parent
                            anchors.margins: root.pad
                            text: desktopEntry ? (desktopEntry.execString || desktopEntry.exec || "") : ""
                            color: Config.styling.text0
                            font.pixelSize: root.monoPx
                            font.family: "monospace"
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: root.lineGap

                    Text {
                        text: "Actions"
                        color: Config.styling.text0
                        font.pixelSize: root.titlePx
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Config.styling.bg4
                    }

                    Column {
                        width: parent.width
                        spacing: root.gap
                        visible: actionList.length > 0

                        Repeater {
                            model: actionList
                            delegate: Item {
                                id: actionRow
                                required property var modelData
                                required property int index
                                width: parent.width
                                implicitHeight: actionLayout.implicitHeight + root.lineGap

                                HoverHandler {
                                    id: actionHover
                                    target: actionRow
                                }
                                TapHandler {
                                    target: actionRow
                                    onTapped: {
                                        root.selectedIndex = index + 1;
                                        root.executeSelected(index + 1);
                                    }
                                }

                                ActiveIndicator {
                                    anchors.fill: parent
                                    side: ActiveIndicator.Side.Left
                                    animationMode: ActiveIndicator.AnimationMode.GrowAll
                                    thickness: Pixels.mm(1.5, screen)
                                    bgActive: actionHover.hovered || (root.selectedIndex - 1) === index
                                    active: (root.selectedIndex - 1) === index
                                }

                                RowLayout {
                                    id: actionLayout
                                    anchors.fill: parent
                                    anchors.leftMargin: root.pad
                                    anchors.rightMargin: root.pad
                                    spacing: root.lineGap

                                    Icon {
                                        readonly property real sizeHint: root.iconSize * root.actionIconScale
                                        Layout.preferredWidth: sizeHint
                                        Layout.preferredHeight: sizeHint
                                        Layout.alignment: Qt.AlignVCenter
                                        iconName: (modelData && modelData.icon) ? modelData.icon : (root.desktopEntry ? root.desktopEntry.icon : "dialog-information")
                                        fallbackIconName: "dialog-information"
                                        smooth: true
                                    }

                                    ColumnLayout {
                                        id: actionTexts
                                        Layout.fillWidth: true
                                        spacing: root.lineGap

                                        Text {
                                            text: modelData && modelData.name ? modelData.name : "Action"
                                            color: Config.styling.text0
                                            font.pixelSize: root.bodyPx
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData ? (modelData.execString || modelData.exec || "") : ""
                                            visible: text.length > 0
                                            color: Config.styling.text2
                                            font.pixelSize: root.monoPx
                                            font.family: "monospace"
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "No additional actions"
                        visible: actionList.length === 0
                        color: Config.styling.text1
                        font.pixelSize: root.bodyPx
                        elide: Text.ElideRight
                    }
                }

                Column {
                    width: parent.width
                    spacing: root.lineGap
                    visible: detailsRows.length > 0

                    Text {
                        text: "Details"
                        color: Config.styling.text0
                        font.pixelSize: root.titlePx
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Config.styling.bg4
                    }

                    Column {
                        width: parent.width
                        spacing: root.gap

                        Repeater {
                            model: detailsRows
                            delegate: Column {
                                width: parent.width
                                spacing: root.lineGap

                                Text {
                                    text: modelData.label
                                    color: Config.styling.text1
                                    font.pixelSize: root.bodyPx
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.value
                                    color: Config.styling.text0
                                    font.pixelSize: root.bodyPx
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: ev => {
        if (ev.key === Qt.Key_Escape) {
            ev.accepted = true;
            view.closeDetails();
            return;
        }
        if (ev.key === Qt.Key_Down || ev.key === Qt.Key_Tab) {
            ev.accepted = true;
            root.cycleSelection(+1);
            return;
        }
        if (ev.key === Qt.Key_Up || ev.key === Qt.Key_Backtab) {
            ev.accepted = true;
            root.cycleSelection(-1);
            return;
        }
        if ((ev.modifiers & Qt.ControlModifier) && [Qt.Key_N, Qt.Key_J].includes(ev.key)) {
            ev.accepted = true;
            root.cycleSelection(+1);
            return;
        }
        if ((ev.modifiers & Qt.ControlModifier) && [Qt.Key_P, Qt.Key_K].includes(ev.key)) {
            ev.accepted = true;
            root.cycleSelection(-1);
            return;
        }
        if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
            ev.accepted = true;
            root.executeSelected(root.selectedIndex);
            return;
        }
    }

    onActionListChanged: clampSelection()
    Component.onCompleted: clampSelection()
}
