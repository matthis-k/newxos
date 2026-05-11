pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../modules/bar" as Bar
import "../modules/quickmenu" as Quickmenu
import "../modules/hyprlandPreview" as HyprlandPreview
import "../modules/applauncher" as AppLauncher
import "../modules/background" as Background

Singleton {
    id: root

    readonly property alias instances: screenStates.instances

    component ScreenState: QtObject {
        id: screenState

        required property ShellScreen modelData
        readonly property ShellScreen screen: screenState.modelData

        property Background.Window background: Background.Window {
            screen: screenState.screen
        }

        property Bar.Window bar: Bar.Window {
            screen: screenState.screen
            IpcHandler {
                target: `bar-${screen.name}`
                function open() {
                    bar.open();
                }
                function close() {
                    bar.close();
                }
                function toggle() {
                    bar.toggle();
                }
            }
        }

        property Quickmenu.Window quickmenu: Quickmenu.Window {
            screen: screenState.screen
        }

        property HyprlandPreview.Window hyprlandPreview: HyprlandPreview.Window {
            screen: screenState.screen
        }

        property AppLauncher.Window appLauncher: AppLauncher.Window {
            screen: screenState.screen
            IpcHandler {
                target: `applauncher-${screen.name}`
                function open() {
                    appLauncher.open();
                }
                function close() {
                    appLauncher.close();
                }
                function toggle() {
                    appLauncher.toggle();
                }
            }
        }
    }

    Variants {
        id: screenStates
        model: Quickshell.screens
        delegate: ScreenState {}
    }

    function forActiveScreens(callback) {
        Quickshell.screens.filter(screen => Hyprland.focusedMonitor && Hyprland.focusedMonitor == Hyprland.monitorFor(screen)).forEach(callback);
    }

    IpcHandler {
        target: "bar"
        function open() {
            forActiveScreens(screen => getScreenByName(screen.name).bar.open());
        }
        function close() {
            forActiveScreens(screen => getScreenByName(screen.name).bar.close());
        }
        function toggle() {
            forActiveScreens(screen => getScreenByName(screen.name).bar.toggle());
        }
    }
    IpcHandler {
        target: "applauncher"
        function open() {
            forActiveScreens(screen => getScreenByName(screen.name).appLauncher.open());
        }
        function close() {
            forActiveScreens(screen => getScreenByName(screen.name).appLauncher.close());
        }
        function toggle() {
            forActiveScreens(screen => getScreenByName(screen.name).appLauncher.toggle());
        }
    }

    function getScreenByName(screenName: string): ScreenState {
        return root.instances.find(screenState => screenState.screen.name == screenName);
    }

    function getScreenByRegex(screenRegex: string): list<ScreenState> {
        return root.instances.filter(screen => screen.name.matches(screenRegex));
    }
}
