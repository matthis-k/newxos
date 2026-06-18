pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
    id: root

    signal launcherOpenRequested(var arg)
    signal launcherCloseRequested()
    signal dashboardOpenRequested(string tab)
    signal dashboardToggleRequested(string tab)

    signal hyprlandPreviewRequested(var screen, var toplevel, real x)
    signal hyprlandPreviewHoverDelta(var screen, int delta)

    signal notificationRequested(var payload)

    function openLauncher(arg: var): void {
        launcherOpenRequested(arg);
    }

    function closeLauncher(): void {
        launcherCloseRequested();
    }

    function openDashboard(tab: string): void {
        dashboardOpenRequested(tab);
    }

    function toggleDashboard(tab: string): void {
        dashboardToggleRequested(tab);
    }

    function requestHyprlandPreview(screen: var, toplevel: var, x: real): void {
        hyprlandPreviewRequested(screen, toplevel, x);
    }

    function addHyprlandPreviewHover(screen: var, delta: int): void {
        hyprlandPreviewHoverDelta(screen, delta);
    }

    function notify(payload: var): void {
        notificationRequested(payload);
    }
}
