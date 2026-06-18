import QtQml
import Quickshell

    import qs.services
    import ".." as Launcher

TreeBackendBase {
    id: root

    property var shellScreenState: null
    readonly property var defaultFlatGroupOptions: ({
        breadcrumbMode: "always",
        flattenAllChildrenOnParentMatch: true,
        maxNestedChildren: 5
    })
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

    Connections {
        target: AudioService
        function on_RevisionChanged() { root.invalidateCompositeRootCache(); }
    }
    Connections {
        target: VpnService
        function onConnectedChanged() { root.invalidateCompositeRootCache(); }
        function onConnectingChanged() { root.invalidateCompositeRootCache(); }
    }
    Connections {
        target: BluetoothService
        function on_RevisionChanged() { root.invalidateCompositeRootCache(); }
    }
    Connections {
        target: PowerService
        function onProfileChanged() { root.invalidateCompositeRootCache(); }
    }

    Connections {
        target: NotificationCenter
        function onDoNotDisturbEnabledChanged() { root.invalidateCompositeRootCache(); }
        function onHasCriticalChanged() { root.invalidateCompositeRootCache(); }
    }

    Connections {
        target: NetworkService
        function onWifiEnabledChanged() { root.invalidateCompositeRootCache(); }
        function onWifiHardwareEnabledChanged() { root.invalidateCompositeRootCache(); }
        function onConnectedSsidChanged() { root.invalidateCompositeRootCache(); }
        function onHasWiredConnectionChanged() { root.invalidateCompositeRootCache(); }
        function onConnectedNetworkChanged() { root.invalidateCompositeRootCache(); }
    }

    function effectiveTreeRoots() {
        var roots = [audioTree(), brightnessTree(), root.powerProfileTree()];
        for (var ni = 0; ni < root.nodes.length; ni += 1) {
            var node = root.nodes[ni];
            if (node && typeof node.toTreeObject === "function")
                roots.push(node.toTreeObject());
        }
        return roots.filter(Boolean);
    }

        FlatActionGroupNode {
            name: "newxos"
            aliases: ["newxos", "nx", "repo"]
            title: qsTr("Newxos")
            icon: "nix-snowflake-symbolic"
            groupOptions: Object.assign({}, root.defaultFlatGroupOptions, { committedTokenPrefersGroup: true, committedTokenMinParentScore: 0.15, showAllChildrenOnParentMatch: true, flattenAllChildrenOnParentMatch: true, parentMatchMinScore: 0.1 })
            behavior: ({
                filterable: true,
                presentation: "discoverable-command-group",
                displayPolicy: {
                    discoverable: true,
                    breadcrumbMode: "when-parent-dominates"
                }
            })

        ActionNode {
            name: "switch"
            aliases: ["switch", "rebuild"]
            title: qsTr("Switch System")
            subtitle: qsTr("Switch this system to the current flake")
            icon: "system-run-symbolic"
            iconColor: Config.styling.primaryAccent
            actionId: "newxos-switch"
            action: function() { launchTerminalPaused(qsTr("newxos switch"), "newxos switch"); }
            risk: ({ level: "privileged", activation: "confirm" })
        }

        ActionNode {
            name: "ai"
            aliases: ["ai", "opencode"]
            title: qsTr("AI")
            subtitle: qsTr("Open opencode in the repo")
            icon: "utilities-terminal-symbolic"
            iconColor: Config.styling.secondaryAccent
            actionId: "newxos-ai"
            action: function() { launchTerminal("newxos ai"); }
        }

        ActionNode {
            name: "git"
            aliases: ["git", "log", "lg", "lazygit"]
            title: qsTr("Git")
            subtitle: qsTr("Open lazygit in the repo")
            icon: "git-symbolic"
            iconColor: Config.styling.info
            actionId: "newxos-git"
            action: function() { launchTerminal("cd \"$NEWXOS_FLAKE\" && lazygit"); }
        }

        ActionNode {
            name: "reload_shell"
            aliases: ["reload", "shell", "restart", "newshell"]
            title: qsTr("Reload Shell")
            subtitle: qsTr("Restart the newshell user service")
            icon: "view-refresh-symbolic"
            iconColor: Config.styling.warning
            actionId: "newxos-reload-shell"
            action: function() { Quickshell.execDetached({ command: ["newxos", "reload_shell"] }); }
        }

        SwitchNode {
            name: "devmode"; aliases: ["dev", "devmode", "dev-mode"]; title: qsTr("Dev Mode")
            subtitle: qsTr("Switch between default and dev specialization")
            icon: "applications-development-symbolic"; iconColor: Config.styling.urgent
            switchState: isDevMode()
            switchActionId: "newxos-devmode"
            switchOnAliases: ["no"]; switchOffAliases: ["nf"]; switchToggleAliases: ["nt"]
            onAction: function() { setDevMode(true); }
            offAction: function() { setDevMode(false); }
            toggleAction: function() { setDevMode(null); }
        }
    }

        FlatActionGroupNode {
            name: "session"
            aliases: ["session", "system"]
            title: qsTr("Session")
            icon: "system-shutdown-symbolic"
            groupOptions: ({ flattenAllChildrenOnParentMatch: true, maxNestedChildren: 5, parentMatchMinScore: 0 })
            behavior: ({ filterable: true })

        ActionNode {
            name: "lock"
            aliases: ["lock"]
            title: qsTr("Lock")
            subtitle: qsTr("Lock the current session")
            icon: "system-lock-screen-symbolic"
            iconColor: Config.styling.info
            actionId: "lock"
            action: function() { Quickshell.execDetached({ command: ["loginctl", "lock-session"] }); }
        }

        ActionNode {
            name: "logout"
            aliases: ["logout", "exit"]
            title: qsTr("Log Out")
            subtitle: qsTr("Exit the current Hyprland session")
            icon: "system-log-out-symbolic"
            iconColor: Config.styling.warning
            dangerous: true
            risk: ({ level: "session", activation: "confirm-and-explicit-prefix" })
            actionId: "logout"
            action: function() { Quickshell.execDetached({ command: ["hyprctl", "dispatch", "exit"] }); }
        }

        ActionNode {
            name: "shutdown"
            aliases: ["shutdown", "poweroff", "power-off"]
            title: qsTr("Shut Down")
            subtitle: qsTr("Power off this machine")
            icon: "system-shutdown-symbolic"
            iconColor: Config.styling.critical
            dangerous: true
            risk: ({ level: "power", activation: "confirm-and-explicit-prefix" })
            actionId: "shutdown"
            action: function() { Quickshell.execDetached({ command: ["systemctl", "poweroff"] }); }
        }

        ActionNode {
            name: "reboot"
            aliases: ["reboot", "restart"]
            title: qsTr("Reboot")
            subtitle: qsTr("Restart this machine")
            icon: "system-reboot-symbolic"
            iconColor: Config.styling.urgent
            dangerous: true
            risk: ({ level: "power", activation: "confirm-and-explicit-prefix" })
            actionId: "reboot"
            action: function() { Quickshell.execDetached({ command: ["systemctl", "reboot"] }); }
        }

        ActionNode {
            name: "hibernate"
            aliases: ["hibernate", "suspend-to-disk"]
            title: qsTr("Hibernate")
            subtitle: qsTr("Suspend this machine to disk")
            icon: "system-suspend-hibernate-symbolic"
            iconColor: Config.styling.secondaryAccent
            dangerous: true
            risk: ({ level: "power", activation: "confirm-and-explicit-prefix" })
            actionId: "hibernate"
            action: function() { Quickshell.execDetached({ command: ["systemctl", "hibernate"] }); }
        }
    }

    FlatActionGroupNode {
        name: "screenshot"
        aliases: ["ss", "screenshot"]
        title: qsTr("Screenshot")
        icon: "camera-photo-symbolic"
        iconColor: Config.styling.secondaryAccent
        behavior: ({ filterable: true })
        ActionNode {
            name: "area"
            aliases: ["area", "region"]
            title: qsTr("Area")
            subtitle: qsTr("Capture a selected region")
            icon: "image-region-symbolic"
            iconColor: Config.styling.primaryAccent
            actionId: "screenshot"
            actionProps: ({ mode: "area" })
            action: function() { screenshotArea(); }
        }

        ActionNode {
            name: "window"
            aliases: ["window"]
            title: qsTr("Window")
            subtitle: qsTr("Capture the active window")
            icon: "window-symbolic"
            iconColor: Config.styling.secondaryAccent
            actionId: "screenshot"
            actionProps: ({ mode: "window" })
            action: function() { screenshotWindow(); }
        }

        ActionNode {
            name: "screen"
            aliases: ["screen", "full", "display"]
            title: qsTr("Screen")
            subtitle: qsTr("Capture all displays")
            icon: "video-display-symbolic"
            iconColor: Config.styling.info
            actionId: "screenshot"
            actionProps: ({ mode: "screen" })
            action: function() { screenshotScreen(); }
        }

        ActionNode {
            name: "read"
            aliases: ["read", "ocr", "text"]
            title: qsTr("Read")
            subtitle: qsTr("Extract text from clipboard image (OCR)")
            icon: "text-editor-symbolic"
            iconColor: Config.styling.good
            actionId: "screenshot"
            actionProps: ({ mode: "read" })
            action: function() { screenshotRead(); }
        }

        ActionNode {
            name: "annotate"
            aliases: ["annotate", "edit", "satty"]
            title: qsTr("Annotate")
            subtitle: qsTr("Annotate clipboard image with satty")
            icon: "image-x-generic-symbolic"
            iconColor: Config.styling.urgent
            actionId: "screenshot"
            actionProps: ({ mode: "annotate" })
            action: function() { screenshotAnnotate(); }
        }
    }

    FlatActionGroupNode {
        name: "dashboard"
        aliases: ["db", "dashboard"]
        title: qsTr("Dashboard")
        icon: dashboardIconForTab("overview")
        iconColor: colorForDashboardTab("overview")
        groupOptions: ({
            flattenAllChildrenOnParentMatch: true,
            maxNestedChildren: 8
        })
        behavior: ({ filterable: true })
        dynamicChildren: dashboardTabNodes()
        actionId: "dashboard"
        actionProps: ({ tab: "overview" })
        action: function() {
            if (shellScreenState)
                shellScreenState.openDashboard("overview");
        }
    }

    FlatActionGroupNode {
        name: "network"
        aliases: ["net", "network", "networking"]
        title: qsTr("Networking")
        icon: "network-wireless-symbolic"
        iconColor: Config.styling.primaryAccent
        groupOptions: ({
            flattenAllChildrenOnParentMatch: true,
            maxNestedChildren: 8
        })
        behavior: ({ filterable: true })
        SwitchNode {
            name: "wifi"; aliases: ["wifi", "wi-fi"]; title: qsTr("Wi-Fi")
            icon: "network-wireless-symbolic"
            iconColor: NetworkService.wifiEnabled ? Config.styling.primaryAccent : Config.styling.text1
            switchState: NetworkService.wifiEnabled
            onAction: function() { setWifi(true); }
            offAction: function() { setWifi(false); }
            toggleAction: function() { setWifi(null); }
        }

        SwitchNode {
            name: "vpn"
            aliases: ["vpn", "nordvpn", "connect to"]
            title: qsTr("VPN")
            icon: "network-vpn-symbolic"
            iconColor: VpnService.connected || VpnService.connecting ? Config.styling.good : Config.styling.warning
            switchState: VpnService.connected || VpnService.connecting
            switchActionId: "vpn"
            switchOnAliases: ["connect", "on", "up"]
            switchOffAliases: ["disconnect", "off", "down"]
            switchToggleAliases: ["toggle"]
            childVisible: ["own-score-min:0.25", "expand-on-trailing-space"]
            dynamicChildren: buildVpnConnectChildren()
            groupOptions: ({
                showAllChildrenOnParentMatch: false,
                flattenAllChildrenOnParentMatch: false,
                maxNestedChildren: 8
            })
            behavior: ({ filterable: true })
            onAction: function() { VpnService.connect(null); }
            offAction: function() { VpnService.disconnect(); }
            toggleAction: function() {
                VpnService.toggle();
            }
        }

        SwitchNode {
            name: "bluetooth"; aliases: ["bt", "bluetooth"]; title: qsTr("Bluetooth")
            icon: BluetoothService.iconName
            iconColor: BluetoothService.enabled ? Config.styling.bluetooth : Config.styling.text1
            switchState: BluetoothService.enabled
            switchToggleAliases: ["btt"]
            onAction: function() { setBluetooth(true); }
            offAction: function() { setBluetooth(false); }
            toggleAction: function() { setBluetooth(null); }
            Component.onCompleted: {
                Launcher.BindingRegistry.register("bluetooth", "liveIcon", BluetoothService, "iconName");
                Launcher.BindingRegistry.register("bluetooth", "liveIconColor", BluetoothService, "iconColor");
                Launcher.BindingRegistry.register("bluetooth", "liveSwitchState", BluetoothService, "enabled");
            }
        }
    }

    FlatActionGroupNode {
        name: "notifications"
        aliases: ["notif", "notifications", "notification"]
        title: qsTr("Notifications")
        icon: "bell-symbolic"
        iconColor: Config.styling.warning
        groupOptions: ({
            flattenAllChildrenOnParentMatch: true,
            maxNestedChildren: 8
        })
        behavior: ({ filterable: true })
        SwitchNode {
            name: "dnd"; aliases: ["dnd"]; title: qsTr("Do Not Disturb")
            icon: "bell-disabled-symbolic"
            iconColor: NotificationCenter.doNotDisturbEnabled ? Config.styling.warning : Config.styling.text1
            switchState: NotificationCenter.doNotDisturbEnabled
            switchOffDangerous: false
            onAction: function() { setDnd(true); }
            offAction: function() { setDnd(false); }
            toggleAction: function() { setDnd(null); }
        }

        ActionNode {
            name: "clear"
            aliases: ["clear", "clear-all"]
            title: qsTr("Clear All")
            subtitle: qsTr("Dismiss all current notifications")
            icon: "user-trash-symbolic"
            iconColor: Config.styling.critical
            actionId: "clear-notifications"
            action: function() { NotificationCenter.clearAll(); }
        }
    }

    function buildVpnConnectChildren() {
        var children = [];

        children.push(actionNode({
            id: "fastest",
            title: qsTr("Fastest server"),
            keywords: ["vpn"],
            icon: "network-vpn-symbolic",
            iconColor: Config.styling.good,
            actionId: "vpn",
            actionProps: { state: "connect" },
            execute: function() { VpnService.connect(null); }
        }));

        (NordVPN.countries || []).forEach(function(country) {
            children.push(actionNode({
                id: "country-" + country,
                title: country,
                keywords: ["vpn"],
                subtitle: qsTr("Country"),
                icon: "network-vpn-symbolic",
                iconColor: Config.styling.good,
                actionId: "vpn",
                actionProps: { state: "connect", destination: country },
                execute: function() { VpnService.connect(country); }
            }));
        });

        (NordVPN.groups || []).forEach(function(group) {
            const title = vpnGroupTitle(group);
            children.push(actionNode({
                id: "group-" + group,
                title: title,
                aliases: [title],
                keywords: ["vpn"],
                subtitle: qsTr("Group"),
                icon: "network-vpn-symbolic",
                iconColor: Config.styling.info,
                actionId: "vpn",
                actionProps: { state: "connect", destination: group },
                execute: function() { VpnService.connect(group); }
            }));
        });

        return children;
    }

    function vpnGroupTitle(group) {
        return String(group || "")
            .replace(/_/g, " ")
            .replace(/\bVPN\b/g, "")
            .replace(/\s+/g, " ")
            .trim();
    }

    function audioTree() {
        return {
            id: "audio",
            aliases: ["audio", "sound", "volume", "mute"],
            title: qsTr("Audio"),
            icon: AudioService.outputIconName,
            iconColor: AudioService.outputMuted ? Config.styling.critical : Config.styling.secondaryAccent,
            template: "flat-action-group",
            groupOptions: { flattenAllChildrenOnParentMatch: true, maxNestedChildren: 10 },
            behavior: { filterable: true },
            children: audioSinkNodes()
        };
    }

    function brightnessTree() {
        return {
            id: "brightness",
            aliases: ["brightness", "backlight", "screen"],
            title: qsTr("Brightness"),
            subtitle: Brightness.available ? qsTr("Screen brightness") : qsTr("Backlight unavailable"),
            icon: Brightness.iconName,
            iconColor: Brightness.available ? Config.styling.primaryAccent : Config.styling.text2,
            template: "flat-action-group",
            groupOptions: { flattenAllChildrenOnParentMatch: true, maxNestedChildren: 3 },
            behavior: { filterable: true },
            children: [{
                id: "brightness-volume",
                aliases: ["brightness", "level", "slider"],
                title: qsTr("Brightness"),
                subtitle: Brightness.available ? (Brightness.percent + "%") : qsTr("Unavailable"),
                icon: Brightness.iconName,
                iconColor: Brightness.available ? Config.styling.primaryAccent : Config.styling.text2,
                control: { kind: "slider", target: "brightness", from: 0, to: 100, step: 5, value: Brightness.percent }
            }]
        };
    }

    function powerProfileTree() {
        return {
            id: "power-profile",
            aliases: ["powermode", "power-mode", "profile", "power", "energy"],
            title: qsTr("Power Mode"),
            subtitle: PowerService.profileLabel(PowerService.profile),
            icon: PowerService.profileIconName(PowerService.profile),
            iconColor: PowerService.profileColor(PowerService.profile),
            control: {
                kind: "slider",
                target: "power-profile",
                from: 0,
                to: 2,
                step: 1,
                value: PowerService.profileIndex(PowerService.profile)
            },
            behavior: { filterable: true }
        };
    }

    function audioSinkNodes() {
        var entries = AudioService.outputDeviceEntries();
        return entries.map(function(entry) {
            var streams = AudioService.streamEntriesForOutput(entry.id);
            var children = streams.length > 0 ? [streamGroupNode(streams)] : [];
            return {
                id: "sink-" + entry.id,
                aliases: ["sink", "output", "speaker", entry.name],
                title: entry.name,
                subtitle: entry.default ? qsTr("Default output") : qsTr("Output"),
                icon: entry.iconName,
                iconColor: entry.muted ? Config.styling.critical : Config.styling.secondaryAccent,
                template: "flat-action-group",
                groupOptions: { flattenAllChildrenOnParentMatch: true, maxNestedChildren: 8 },
                behavior: { filterable: true },
                switchState: entry.muted,
                control: entry.control,
                switchActions: entry.switchActions,
                children: children
            };
        });
    }

    function streamGroupNode(streams) {
        return {
            id: "streams",
            aliases: ["streams", "apps", "applications"],
            title: qsTr("Streams"),
            subtitle: streams.length + " " + qsTr("active"),
            icon: "audio-x-generic-symbolic",
            iconColor: Config.styling.text1,
            template: "flat-action-group",
            groupOptions: { flattenAllChildrenOnParentMatch: true, maxNestedChildren: 8 },
            behavior: { filterable: true },
            children: streams.map(function(stream) { return volumeSliderNode(stream); })
        };
    }

    function volumeSliderNode(stream) {
        return {
            id: "stream-" + stream.id,
            aliases: ["stream", "volume", stream.name],
            title: stream.name,
            subtitle: stream.volume + "%",
            icon: stream.iconName,
            iconColor: stream.muted ? Config.styling.critical : Config.styling.secondaryAccent,
            control: stream.control
        };
    }

    function titleForDashboardTab(tab) {
        switch (tab) {
        case "wifi": return "Wi-Fi";
        default: return tab;
        }
    }

    function dashboardTabNodes() {
        var tabs = (shellScreenState && shellScreenState.dashboardTabs) || ["overview", "audio", "notifications", "bluetooth", "wifi", "energy", "stats"];
        return tabs.map(function(tab) { return actionNode({
            id: tab,
            title: titleForDashboardTab(tab),
            icon: dashboardIconForTab(tab),
            iconColor: colorForDashboardTab(tab),
            actionId: "dashboard",
            actionProps: { tab: tab },
            execute: function() {
                if (shellScreenState)
                    shellScreenState.openDashboard(tab);
            }
        }); });
    }

    function dashboardIconForTab(tab) {
        switch (tab) {
        case "overview": return "view-grid-symbolic";
        case "audio": return AudioService.outputIconName;
        case "notifications": return NotificationCenter.doNotDisturbEnabled ? "bell-disabled-symbolic" : "bell-symbolic";
        case "bluetooth": return BluetoothService.iconName;
        case "wifi": return networkIconName();
        case "energy": return PowerService.iconName;
        case "stats": return "utilities-system-monitor-symbolic";
        default: return "view-grid-symbolic";
        }
    }

    function colorForDashboardTab(tab) {
        switch (tab) {
        case "overview": return overviewIconColor();
        case "audio": return AudioService.outputMuted ? Config.styling.critical : (AudioService.outputVolume === 0 ? Config.styling.warning : Config.styling.text0);
        case "notifications": return notificationIconColor();
        case "bluetooth": return BluetoothService.enabled ? Config.styling.bluetooth : Config.styling.critical;
        case "wifi": return Config.styling.text0;
        case "energy": return PowerService.iconColor;
        case "stats": return Stats.presentation.color;
        default: return overviewIconColor();
        }
    }

    function overviewIconColor() {
        var muted = AudioService.outputMuted;
        var batteryCritical = PowerService.hasBattery && PowerService.batteryPercent <= 10;
        var networkOffline = !NetworkService.connectedSsid && !NetworkService.hasWiredConnection;

        if (NotificationCenter.hasCritical || batteryCritical)
            return Config.styling.critical;
        if (muted || networkOffline)
            return Config.styling.warning;
        return Config.styling.primaryAccent;
    }

    function notificationIconColor() {
        if (NotificationCenter.hasCritical)
            return Config.styling.critical;
        if (NotificationCenter.doNotDisturbEnabled)
            return Config.styling.warning;
        return Config.styling.text0;
    }

    function networkIconName() {
        var connectedNetwork = NetworkService.connectedNetwork;

        if (NetworkService.hasWiredConnection)
            return "network-wired-symbolic";
        if (!NetworkService.wifiHardwareEnabled)
            return "network-wireless-disabled-symbolic";
        if (connectedNetwork)
            return NetworkService.wifiIconName(connectedNetwork);
        return NetworkService.wifiEnabled ? "network-wireless-offline-symbolic" : "network-wireless-disabled-symbolic";
    }

    function setWifi(state) {
        var enabled = state === null ? !NetworkService.wifiEnabled : state;
        NetworkService.setWifiEnabled(enabled);
    }

    function setBluetooth(state) {
        var enabled = state === null ? !BluetoothService.enabled : state;
        BluetoothService.setEnabled(enabled);
    }

    function setDnd(state) {
        var enabled = state === null ? !NotificationCenter.doNotDisturbEnabled : state;
        NotificationCenter.setDoNotDisturb(enabled);
    }

    function isDevMode() {
        return Quickshell.env("NEWXOS_DEV") === "1" || Quickshell.env("DEVMODE") === "1";
    }

    function setDevMode(state) {
        var enabled = state === null ? !isDevMode() : state;
        if (enabled)
            launchTerminalPaused(qsTr("Enable dev mode"), "if [ -x /run/current-system/specialisation/dev/bin/switch-to-configuration ]; then sudo /run/current-system/specialisation/dev/bin/switch-to-configuration test; else printf '%s\\n' 'dev specialization is not available'; exit 1; fi");
        else
            launchTerminalPaused(qsTr("Disable dev mode"), "sudo /run/current-system/bin/switch-to-configuration test");
    }

    function screenshotArea() {
        Quickshell.execDetached({ command: ["grimblast", "--notify", "copysave", "area"] });
    }

    function screenshotWindow() {
        Quickshell.execDetached({ command: ["grimblast", "--notify", "copysave", "active"] });
    }

    function screenshotScreen() {
        Quickshell.execDetached({ command: ["grimblast", "--notify", "copysave", "output"] });
    }

    function screenshotRead() {
        Quickshell.execDetached({ command: ["sh", "-c", "read-image --clipboard | wl-copy && notify-send 'Screen OCR' 'Copied text to clipboard'"] });
    }

    function screenshotAnnotate() {
        Quickshell.execDetached({ command: ["annotate", "--clipboard"] });
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

    function activate(result, action) {
        var metadata = result ? result.metadata || {} : {};
        var cmdAction = actionPayloadForPath(metadata.commandPath || [], action ? action.id : metadata.actionId) || (action && action.payload) || {};
        if (typeof cmdAction.execute === "function")
            cmdAction.execute();
    }
}
