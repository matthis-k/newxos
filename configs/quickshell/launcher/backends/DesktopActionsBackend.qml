import QtQml
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

import qs.services
import "../logic/CommandTree.js" as CommandTree

CommandTreeBackendBase {
    id: root

    property var shellScreenState: null
    property var controller: null

    category: qsTr("Desktop Actions")

    backendId: "desktop-actions"
    name: qsTr("Desktop Actions")
    helpTitle: qsTr("Desktop Actions")
    helpDescription: qsTr("Run session, hardware, and dashboard actions")
    helpIcon: "system-run"
    helpPrefixes: [":", "!"]
    priority: 120
    maxResults: 8
    routes: [
        { pattern: "^[:!]\\s?(.*)", mode: "participate" },
        { pattern: "^.*$", mode: "ambient" }
    ]

    treePrefixes: [":", "!"]
    treeRoots: actionTree

    readonly property var actionTree: [
        {
            id: "dashboard",
            aliases: ["db", "dashboard"],
            title: qsTr("Dashboard"),
            icon: "view-dashboard-symbolic",
            defaultAction: { actionId: "dashboard", tab: "overview" },
            children: dashboardTabNodes()
        },
        {
            id: "wifi",
            aliases: ["wifi", "wi-fi"],
            title: qsTr("Wi-Fi"),
            icon: "network-wireless-symbolic",
            children: stateNodes("wifi")
        },
        {
            id: "bluetooth",
            aliases: ["bt", "bluetooth"],
            title: qsTr("Bluetooth"),
            icon: "bluetooth-symbolic",
            children: stateNodes("bluetooth")
        },
        {
            id: "mute",
            aliases: ["mute", "audio"],
            title: qsTr("Toggle Mute"),
            subtitle: qsTr("Mute or unmute the default output"),
            icon: "audio-volume-muted-symbolic",
            action: { actionId: "mute" }
        },
        {
            id: "mic",
            aliases: ["mic", "microphone"],
            title: qsTr("Toggle Microphone Mute"),
            subtitle: qsTr("Mute or unmute the default input"),
            icon: "microphone-sensitivity-muted-symbolic",
            action: { actionId: "mic" }
        },
        {
            id: "dnd",
            aliases: ["dnd", "notifications"],
            title: qsTr("Do Not Disturb"),
            icon: "bell-disabled-symbolic",
            children: stateNodes("dnd")
        },
        {
            id: "logout",
            aliases: ["logout", "exit"],
            title: qsTr("Log Out"),
            subtitle: qsTr("Exit the current Hyprland session"),
            icon: "system-log-out-symbolic",
            action: { actionId: "logout" },
            dangerous: true
        },
        {
            id: "shutdown",
            aliases: ["shutdown", "poweroff", "power-off"],
            title: qsTr("Shut Down"),
            subtitle: qsTr("Power off this machine"),
            icon: "system-shutdown-symbolic",
            action: { actionId: "shutdown" },
            dangerous: true
        },
        {
            id: "reboot",
            aliases: ["reboot", "restart"],
            title: qsTr("Reboot"),
            subtitle: qsTr("Restart this machine"),
            icon: "system-reboot-symbolic",
            action: { actionId: "reboot" },
            dangerous: true
        },
        {
            id: "lock",
            aliases: ["lock"],
            title: qsTr("Lock"),
            subtitle: qsTr("Lock the current session"),
            icon: "system-lock-screen-symbolic",
            action: { actionId: "lock" }
        }
    ]

    function dashboardTabNodes() {
        var tabs = shellScreenState ? shellScreenState.dashboardTabs : ["overview", "audio", "notifications", "bluetooth", "wifi", "energy", "stats"];
        return tabs.map(function(tab) { return {
            id: tab,
            title: tab,
            icon: "view-dashboard-symbolic",
            action: { actionId: "dashboard", tab: tab }
        }; });
    }

    function stateNodes(actionId) {
        return [
            { id: "on", title: qsTr("Turn On"), icon: "object-select-symbolic", action: { actionId: actionId, state: true } },
            { id: "off", title: qsTr("Turn Off"), icon: "window-close-symbolic", action: { actionId: actionId, state: false }, dangerous: actionId !== "dnd" },
            { id: "toggle", title: qsTr("Toggle"), icon: "view-refresh-symbolic", action: { actionId: actionId, state: null } }
        ];
    }

    function setWifi(state) {
        var enabled = state === null ? !NetworkService.wifiEnabled : state;
        Quickshell.execDetached({ command: ["nmcli", "radio", "wifi", enabled ? "on" : "off"] });
        NetworkService.refresh();
    }

    function setBluetooth(state) {
        var adapter = Bluetooth.defaultAdapter;
        if (adapter)
            adapter.enabled = state === null ? !adapter.enabled : state;
    }

    function setDnd(state) {
        var enabled = state === null ? !NotificationCenter.doNotDisturbEnabled : state;
        NotificationCenter.toastsEnabled = !enabled;
    }

    function toggleMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function activate(result, action) {
        var metadata = result ? result.metadata || {} : {};
        if (metadata.kind === "completion" && metadata.replaceQuery)
            return;

        var cmdAction = metadata.action || {};
        switch (cmdAction.actionId) {
        case "dashboard":
            if (shellScreenState)
                shellScreenState.openDashboard(cmdAction.tab || "overview");
            break;
        case "wifi":
            setWifi(cmdAction.state);
            break;
        case "bluetooth":
            setBluetooth(cmdAction.state);
            break;
        case "mute":
            toggleMute(Pipewire.defaultAudioSink);
            break;
        case "mic":
            toggleMute(Pipewire.defaultAudioSource);
            break;
        case "dnd":
            setDnd(cmdAction.state);
            break;
        case "logout":
            Quickshell.execDetached({ command: ["hyprctl", "dispatch", "exit"] });
            break;
        case "shutdown":
            Quickshell.execDetached({ command: ["systemctl", "poweroff"] });
            break;
        case "reboot":
            Quickshell.execDetached({ command: ["systemctl", "reboot"] });
            break;
        case "lock":
            Quickshell.execDetached({ command: ["loginctl", "lock-session"] });
            break;
        default:
            break;
        }
    }
}
