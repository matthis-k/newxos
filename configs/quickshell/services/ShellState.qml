pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import "../modules/bar" as Bar
import "../modules/quickmenu" as Quickmenu
import "../modules/hyprlandPreview" as HyprlandPreview
import "../modules/background" as Background
import "../launcher" as Launcher

Singleton {
    id: root

    readonly property alias instances: screenStates.instances

    component ScreenState: QtObject {
        id: screenState

        required property ShellScreen modelData
        readonly property ShellScreen screen: screenState.modelData

        property int dashboardWidth: 392
        // Keep this order in sync with quickmenu/Window.qml SwipeView pages and bar dashboard icons.
        readonly property var dashboardTabs: ["overview", "audio", "notifications", "bluetooth", "wifi", "energy", "stats"]
        property string activeTab: ""
        property string dashboardPhase: "closed"
        readonly property bool dashboardOpen: dashboardPhase !== "closed"
        readonly property bool barExpandedForDashboard: dashboardOpen
        readonly property int dashboardTransitionMs: Config.motion.medium

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

        function stepDashboardTab(offset) {
            if (!dashboardOpen)
                return false;

            const nextTab = dashboardTabs[tabIndex(activeTab) + offset];
            if (!nextTab)
                return false;

            openDashboard(nextTab);
            return true;
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
            topInset: bar.implicitHeight
        }

        property Launcher.Launcher launcher: Launcher.Launcher {
            screen: screenState.screen
            shellScreenState: screenState
        }
    }

    Variants {
        id: screenStates
        model: Quickshell.screens
        delegate: ScreenState {}
    }

    function forActiveScreens(callback) {
        Quickshell.screens.filter(screen => Hyprland.focusedMonitor && Hyprland.focusedMonitor === Hyprland.monitorFor(screen)).forEach(callback);
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
        target: "launcher"
        function open() {
            forActiveScreens(screen => {
                const ss = getScreenByName(screen.name);
                if (ss)
                    ss.launcher.open();
            });
        }
        function openWith(arg: string) {
            try {
                const parsed = JSON.parse(arg);
                forActiveScreens(screen => getScreenByName(screen.name).launcher.open(parsed));
            } catch (e) {
                forActiveScreens(screen => getScreenByName(screen.name).launcher.open(arg));
            }
        }
        function close() {
            forActiveScreens(screen => getScreenByName(screen.name).launcher.close());
        }
        function toggle() {
            forActiveScreens(screen => {
                const ss = getScreenByName(screen.name);
                if (ss) {
                    const launcher = ss.launcher;
                    if (launcher)
                        launcher.visible ? launcher.close() : launcher.open();
                }
            });
        }
        function toggleWith(arg: string) {
            try {
                const parsed = JSON.parse(arg);
                forActiveScreens(screen => {
                    const launcher = getScreenByName(screen.name).launcher;
                    launcher.visible ? launcher.close() : launcher.open(parsed);
                });
            } catch (e) {
                forActiveScreens(screen => {
                    const launcher = getScreenByName(screen.name).launcher;
                    launcher.visible ? launcher.close() : launcher.open(arg);
                });
            }
        }

    }

    IpcHandler {
        target: "query"
        function pipeline(query: string): string {
            const state = root.instances[0];
            return state ? state.launcher.queryPipeline(query) : "{}";
        }
        function policies(query: string): string {
            const state = root.instances[0];
            return state ? state.launcher.queryPolicies(query) : "{}";
        }
        function benchmark(arg: string): string {
            const state = root.instances[0];
            return state ? state.launcher.debugBenchmark(arg) : "{}";
        }
        function cases(): string {
            const state = root.instances[0];
            return state ? state.launcher.queryCases() : "{}";
        }
        function runCases(): string {
            const state = root.instances[0];
            return state ? state.launcher.queryRunCases() : "{}";
        }
        function visual(query: string): string {
            const state = root.instances[0];
            return state ? state.launcher.queryVisual(query) : "{}";
        }
        function visualState(): string {
            const state = root.instances[0];
            return state ? state.launcher.queryVisualState() : "{}";
        }
        function visualApply(query: string): string {
            const state = root.instances[0];
            return state ? state.launcher.queryVisualApply(query) : "{}";
        }
        function visualDebug(enabled: string): string {
            const state = root.instances[0];
            return state ? state.launcher.queryVisualDebug(enabled) : "{}";
        }
    }

    function getScreenByName(screenName: string): ScreenState {
        return root.instances.find(screenState => screenState.screen.name === screenName);
    }

    function getScreenByRegex(screenRegex: string): list<ScreenState> {
        const regex = new RegExp(screenRegex);
        return root.instances.filter(screenState => regex.test(screenState.screen.name));
    }
}
