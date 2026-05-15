pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
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

        property int dashboardWidth: 392
        readonly property var dashboardTabs: ["overview", "audio", "notifications", "bluetooth", "wifi", "energy", "stats"]
        property string activeTab: ""
        property string dashboardPhase: "closed"
        readonly property bool dashboardOpen: dashboardPhase !== "closed"
        readonly property bool barExpandedForDashboard: dashboardOpen
        readonly property int dashboardTransitionMs: Config.behaviour.animation.enabled ? Config.behaviour.animation.calc(0.18) : 0

        function normalizeTab(tabName) {
            const normalized = tabName || "overview";
            return dashboardTabs.indexOf(normalized) >= 0 ? normalized : "overview";
        }

        function tabIndex(tabName) {
            const normalizedTab = normalizeTab(tabName);
            const index = dashboardTabs.indexOf(normalizedTab);
            return index >= 0 ? index : 0;
        }

        function isIndicatorActive(tabName) {
            const normalizedTab = normalizeTab(tabName);
            return activeTab === normalizedTab;
        }

        function finishTransition() {
            switch (dashboardPhase) {
            case "opening":
            case "switching":
                dashboardPhase = "open";
                break;
            case "closing":
                activeTab = "";
                dashboardPhase = "closed";
                break;
            default:
                break;
            }
        }

        function queueTransition() {
            if (dashboardTransitionMs <= 0) {
                finishTransition();
                return;
            }

            transitionTimer.restart();
        }

        function openDashboard(tabName) {
            const normalizedTab = normalizeTab(tabName);
            const sameTarget = dashboardOpen && activeTab === normalizedTab;

            if (sameTarget)
                return;

            activeTab = normalizedTab;
            dashboardPhase = dashboardOpen ? "switching" : "opening";
            queueTransition();
        }

        function closeDashboard() {
            if (!dashboardOpen)
                return;

            dashboardPhase = "closing";
            queueTransition();
        }

        function toggleDashboard(tabName) {
            const normalizedTab = normalizeTab(tabName);

            if (isIndicatorActive(normalizedTab)) {
                closeDashboard();
                return;
            }

            openDashboard(normalizedTab);
        }

        property Timer transitionTimer: Timer {
            id: transitionTimer
            interval: screenState.dashboardTransitionMs
            onTriggered: screenState.finishTransition()
        }

        property Background.Window background: Background.Window {
            screen: screenState.screen
        }

        property Bar.Window bar: Bar.Window {
            screen: screenState.screen
            shellScreenState: screenState
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
            shellScreenState: screenState
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
