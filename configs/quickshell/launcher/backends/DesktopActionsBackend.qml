import QtQml
import Quickshell
import qs.services
import "actions" as Actions

TreeBackendBase {
    id: root

    property var shellScreenState: null
    readonly property var defaultFlatGroupOptions: ({ breadcrumbMode: "always", flattenAllChildrenOnParentMatch: true, maxNestedChildren: 5 })

    category: qsTr("Desktop Actions")
    backendId: "desktop-actions"
    name: qsTr("Desktop Actions")
    helpDescription: qsTr("Run networking, session, system, and dashboard actions")
    helpIcon: "system-run"
    helpPrefixes: [":"]
    priority: 120
    maxResults: 8
    dynamicCompositeRoot: false
    routes: [
        { prefix: ":", priority: 120, combine: "exclusive", afterEmpty: "fallthrough" },
        { priority: 0, combine: "shared", afterEmpty: "stop" }
    ]

    property QtObject newxosActions: Actions.NewxosActions { groupOptions: root.defaultFlatGroupOptions }
    property QtObject sessionActions: Actions.SessionActions {}
    property QtObject screenshotActions: Actions.ScreenshotActions {}
    property QtObject dashboardActions: Actions.DashboardActions { shellScreenState: root.shellScreenState }
    property QtObject networkActions: Actions.NetworkActions {}
    property QtObject audioActions: Actions.AudioActions {}
    property QtObject powerActions: Actions.PowerActions {}
    property QtObject notificationActions: Actions.NotificationActions {}

    Connections { target: AudioService; function on_RevisionChanged() { root.invalidateCompositeRootCache(); } }
    Connections { target: VpnService; function onConnectedChanged() { root.invalidateCompositeRootCache(); } function onConnectingChanged() { root.invalidateCompositeRootCache(); } }
    Connections { target: BluetoothService; function on_RevisionChanged() { root.invalidateCompositeRootCache(); } }
    Connections { target: PowerService; function onProfileChanged() { root.invalidateCompositeRootCache(); } }
    Connections { target: NotificationCenter; function onDoNotDisturbEnabledChanged() { root.invalidateCompositeRootCache(); } function onHasCriticalChanged() { root.invalidateCompositeRootCache(); } }
    Connections { target: NetworkService; function onWifiEnabledChanged() { root.invalidateCompositeRootCache(); } function onWifiHardwareEnabledChanged() { root.invalidateCompositeRootCache(); } function onConnectedSsidChanged() { root.invalidateCompositeRootCache(); } function onHasWiredConnectionChanged() { root.invalidateCompositeRootCache(); } function onConnectedNetworkChanged() { root.invalidateCompositeRootCache(); } }

    function effectiveTreeRoots() {
        return [].concat(
            newxosActions.roots({}),
            sessionActions.roots({}),
            screenshotActions.roots({}),
            dashboardActions.roots({ shellScreenState: root.shellScreenState }),
            networkActions.roots({}),
            audioActions.roots({}),
            powerActions.roots({}),
            notificationActions.roots({})
        ).filter(Boolean);
    }

    function activate(result, action) {
        var payload = action && action.payload || {};
        if (!payload.service)
            return;

        switch (payload.service) {
        case "desktop":
            runDesktopPayload(payload);
            break;
        case "dashboard":
            if (root.shellScreenState)
                root.shellScreenState.openDashboard(payload.tab || "overview");
            break;
        }
    }

    function runDesktopPayload(payload) {
        if (payload.op === "exec" && payload.command) {
            Quickshell.execDetached({ command: payload.command });
        } else if (payload.op === "terminal") {
            if (payload.pausedTitle)
                launchTerminalPaused(payload.pausedTitle, payload.command || "");
            else
                launchTerminal(payload.command || "");
        } else if (payload.op === "devmode") {
            var enabled = payload.enabled === null || payload.enabled === undefined ? !(Quickshell.env("NEWXOS_DEV") === "1" || Quickshell.env("DEVMODE") === "1") : !!payload.enabled;
            if (enabled)
                launchTerminalPaused(qsTr("Enable dev mode"), "if [ -x /run/current-system/specialisation/dev/bin/switch-to-configuration ]; then sudo /run/current-system/specialisation/dev/bin/switch-to-configuration test; else printf '%s\\n' 'dev specialization is not available'; exit 1; fi");
            else
                launchTerminalPaused(qsTr("Disable dev mode"), "sudo /run/current-system/bin/switch-to-configuration test");
        }
    }

    function launchTerminal(command) {
        Quickshell.execDetached({ command: ["systemd-run", "--user", "--scope", "--collect", "--same-dir", "--", "setsid", "sh", "-lc", "exec \"${TERMINAL:-kitty}\" -e sh -lc \"$1\"", "launcher-terminal", command] });
    }

    function launchTerminalPaused(title, command) {
        var script = "printf '%s\\n\\n' " + shellQuote(title) + "; " + command + "; status=$?; printf '\\nPress Enter to close...'; read -r _; exit $status";
        launchTerminal(script);
    }

    function shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
    }
}
