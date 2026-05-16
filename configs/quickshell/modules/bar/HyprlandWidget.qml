import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.components
import qs.modules.hyprlandPreview

Item {
    id: root
    property bool onlyForScreen: true
    property HyprlandMonitor monitor: onlyForScreen ? Hyprland.monitorFor(screen) : null

    implicitHeight: parent.height
    implicitWidth: row.implicitWidth

    function workspaceNumber(workspace) {
        const id = Number(workspace?.id);
        if (Number.isFinite(id) && id > 0)
            return id;

        const name = Number.parseInt(workspace?.name || "", 10);
        return Number.isFinite(name) ? name : Number.MAX_SAFE_INTEGER;
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Config.spacing.xxs

        Repeater {
            id: workspaceRepeater

            model: ScriptModel {
                values: [...Hyprland.workspaces.values].sort((a, b) => {
                    const numberDiff = root.workspaceNumber(a) - root.workspaceNumber(b);
                    if (numberDiff !== 0)
                        return numberDiff;

                    return (a?.name || "").localeCompare(b?.name || "");
                })
            }
            delegate: WorkspaceOverview {}
        }
    }

    component WorkspaceOverview: Item {
        required property HyprlandWorkspace modelData
        property HyprlandWorkspace workspace: modelData

        implicitHeight: root.height
        implicitWidth: ws.implicitWidth + toplevels.implicitWidth

        ActionButton {
            id: ws
            implicitHeight: root.height
            implicitWidth: root.height
            fillOnHover: false
            indicatorOnHover: false
            highlightThickness: 0
            scaleText: true
            textScaleTarget: wsLabel
            hoveredScale: 1.0
            unhoveredScale: 0.8
            baseScale: Hyprland.focusedWorkspace?.id === workspace?.id ? 1.0 : 0.8

            onClicked: {
                if (workspace && Hyprland.focusedWorkspace?.id !== workspace.id) {
                    workspace.activate?.();
                }
            }
        }

        Text {
            id: wsLabel
            text: workspace.name
            anchors.centerIn: ws
            color: (Hyprland.focusedWorkspace?.id === workspace?.id) ? Config.styling.activeIndicator : Config.styling.text0
            font.pixelSize: parent.height
            font.bold: true
        }

        RowLayout {
            id: toplevels
            implicitHeight: root.height
            anchors.left: ws.right
            spacing: 0

            Repeater {
                model: workspace.toplevels

                delegate: TopLevel {
                    toplevel: modelData
                }
            }
        }
    }

    component TopLevel: ActionButton {
        id: tl
        required property HyprlandToplevel modelData
        property HyprlandToplevel toplevel: modelData
        property Component previewComponent: previewFactory
        Component {
            id: previewFactory

            HyprlandToplevelView {
                toplevel: tl.toplevel
            }
        }
        property DesktopEntry entry: {
            DesktopEntries.applications?.values;
            return DesktopEntries.heuristicLookup(toplevel.wayland?.appId);
        }
        property string iconSource: Quickshell.iconPath(entry?.icon, "dialog-warning")

        implicitHeight: root.height
        implicitWidth: root.height
        active: toplevel.activated && Hyprland.focusedWorkspace?.id === toplevel?.workspace.id
        highlightSide: ActiveIndicator.Side.Top
        highlightAnimationMode: ActiveIndicator.AnimationMode.GrowAcross
        highlightThickness: Math.max(2, height * 0.1)
        scaleIcon: true
        iconScaleTarget: tlIcon
        hoveredScale: 1.0
        unhoveredScale: 0.8

        onHoveredChanged: {
            const previewWindow = ShellState.getScreenByName(screen.name).hyprlandPreview;
            if (hovered)
                previewWindow.showPreview(tl.previewComponent);
            previewWindow.externalHovers += hovered ? 1 : -1;
        }

        onClicked: {
            toplevel?.wayland.activate();
        }

        contentItem: Icon {
            id: tlIcon
            anchors.centerIn: parent
            source: iconSource
            implicitSize: parent.height * 0.9
        }

        TapHandler {
            acceptedButtons: Qt.MiddleButton
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: {
                toplevel?.wayland.close();
            }
        }
    }

    Component.onCompleted: {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }
}
