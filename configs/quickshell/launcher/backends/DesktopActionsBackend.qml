import QtQml
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import qs.services

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
        target: Pipewire
        function onDefaultAudioSinkChanged() { root.invalidateCompositeRootCache(); }
    }
    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { root.invalidateCompositeRootCache(); }
    }
    Connections {
        target: Pipewire.linkGroups
        function onValuesChanged() { root.invalidateCompositeRootCache(); }
    }

    function effectiveTreeRoots() {
        var roots = [audioTree(), brightnessTree()];
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
            groupOptions: root.defaultFlatGroupOptions
            behavior: ({ })
        actionId: "newxos-switch"
        action: function() { launchTerminalPaused(qsTr("newxos switch"), "newxos switch"); }

        ActionNode {
            name: "switch"
            aliases: ["switch", "rebuild"]
            title: qsTr("Switch System")
            subtitle: qsTr("Switch this system to the current flake")
            icon: "system-run-symbolic"
            iconColor: Config.styling.primaryAccent
            actionId: "newxos-switch"
            action: function() { launchTerminalPaused(qsTr("newxos switch"), "newxos switch"); }
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
            iconColor: NordVPN.connected || NordVPN.connecting ? Config.styling.good : Config.styling.warning
            switchState: NordVPN.connected || NordVPN.connecting
            switchActionId: "vpn"
            switchOnAliases: ["connect", "on"]
            switchOffAliases: ["disconnect", "off"]
            switchToggleAliases: ["toggle"]
            dynamicChildren: buildVpnConnectChildren()
            groupOptions: ({
                showAllChildrenOnParentMatch: false,
                flattenAllChildrenOnParentMatch: false,
                maxNestedChildren: 8
            })
            behavior: ({ filterable: true })
            onAction: function() { NordVPN.connect(null); }
            offAction: function() { NordVPN.disconnect(); }
            toggleAction: function() {
                if (NordVPN.connected || NordVPN.connecting)
                    NordVPN.disconnect();
                else
                    NordVPN.connect(null);
            }
        }

        SwitchNode {
            name: "bluetooth"; aliases: ["bt", "bluetooth"]; title: qsTr("Bluetooth")
            icon: bluetoothIconName()
            iconColor: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Config.styling.bluetooth : Config.styling.text1
            switchState: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : null
            switchToggleAliases: ["btt"]
            onAction: function() { setBluetooth(true); }
            offAction: function() { setBluetooth(false); }
            toggleAction: function() { setBluetooth(null); }
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

    FlatActionGroupNode {
        name: "power"
        aliases: ["power", "energy"]
        title: qsTr("Power")
        icon: "battery-symbolic"
        iconColor: Config.styling.good
        groupOptions: ({
            flattenAllChildrenOnParentMatch: true,
            maxNestedChildren: 8
        })
        behavior: ({ filterable: true })
        FlatActionGroupNode {
            name: "powermode"
            aliases: ["powermode", "power-mode", "profile"]
            title: qsTr("Power Mode")
            icon: "power-profile-balanced-symbolic"
            iconColor: Config.styling.urgent
            groupOptions: ({
                flattenAllChildrenOnParentMatch: true,
                maxNestedChildren: 8
            })

            ActionNode {
                name: "powersaver"
                aliases: ["powersaver", "power-saver", "save"]
                title: qsTr("Power Saver")
                icon: "power-profile-power-saver-symbolic"
                iconColor: Config.styling.good
                actionId: "powermode"
                actionProps: ({ mode: PowerProfile.PowerSaver })
                action: function() { PowerProfiles.profile = PowerProfile.PowerSaver; }
            }

            ActionNode {
                name: "balanced"
                aliases: ["balanced", "balance"]
                title: qsTr("Balanced")
                icon: "power-profile-balanced-symbolic"
                iconColor: Config.styling.primaryAccent
                actionId: "powermode"
                actionProps: ({ mode: PowerProfile.Balanced })
                action: function() { PowerProfiles.profile = PowerProfile.Balanced; }
            }

            ActionNode {
                name: "performance"
                aliases: ["performance", "perf", "high"]
                title: qsTr("Performance")
                icon: "power-profile-performance-symbolic"
                iconColor: Config.styling.urgent
                actionId: "powermode"
                actionProps: ({ mode: PowerProfile.Performance })
                action: function() { PowerProfiles.profile = PowerProfile.Performance; }
            }
        }
    }

    function buildVpnConnectChildren() {
        var children = [];

        children.push(actionNode({
            id: "fastest",
            title: qsTr("Fastest server"),
            icon: "network-vpn-symbolic",
            iconColor: Config.styling.good,
            actionId: "vpn",
            actionProps: { state: "connect" },
            execute: function() { NordVPN.connect(null); }
        }));

        (NordVPN.countries || []).forEach(function(country) {
            children.push(actionNode({
                id: "country-" + country,
                title: country,
                subtitle: qsTr("Country"),
                icon: "network-vpn-symbolic",
                iconColor: Config.styling.good,
                actionId: "vpn",
                actionProps: { state: "connect", destination: country },
                execute: function() { NordVPN.connect(country); }
            }));
        });

        (NordVPN.groups || []).forEach(function(group) {
            const title = vpnGroupTitle(group);
            children.push(actionNode({
                id: "group-" + group,
                title: title,
                aliases: [title],
                subtitle: qsTr("Group"),
                icon: "network-vpn-symbolic",
                iconColor: Config.styling.info,
                actionId: "vpn",
                actionProps: { state: "connect", destination: group },
                execute: function() { NordVPN.connect(group); }
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
            icon: audioIconName(),
            iconColor: audioIconColor(),
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

    function audioSinkNodes() {
        var sinks = audioNodes(PwNodeType.AudioSink);
        if (sinks.length === 0 && Pipewire.defaultAudioSink)
            sinks.push(Pipewire.defaultAudioSink);
        sinks.sort(function(a, b) {
            var aDefault = Pipewire.defaultAudioSink && a.id === Pipewire.defaultAudioSink.id;
            var bDefault = Pipewire.defaultAudioSink && b.id === Pipewire.defaultAudioSink.id;
            if (aDefault !== bDefault)
                return aDefault ? -1 : 1;
            return nodeTitle(a).localeCompare(nodeTitle(b));
        });
        return sinks.map(function(sink) {
            var streams = outputStreamsForSink(sink);
            var children = streams.length > 0 ? [streamGroupNode(sink, streams)] : [];
            return {
                id: "sink-" + sink.id,
                aliases: ["sink", "output", "speaker", nodeTitle(sink)],
                title: nodeTitle(sink),
                subtitle: Pipewire.defaultAudioSink && sink.id === Pipewire.defaultAudioSink.id ? qsTr("Default output") : qsTr("Output"),
                icon: volumeIconName(sink),
                iconColor: sink.audio && sink.audio.muted ? Config.styling.critical : Config.styling.secondaryAccent,
                template: "flat-action-group",
                groupOptions: { flattenAllChildrenOnParentMatch: true, maxNestedChildren: 8 },
                behavior: { filterable: true },
                switchState: !!(sink.audio && sink.audio.muted),
                control: { kind: "slider", target: "pipewire", nodeId: sink.id, from: 0, to: 150, step: 5, value: sink.audio ? Math.round((sink.audio.volume || 0) * 100) : 0 },
                switchActions: muteSwitchActions(sink),
                children: children
            };
        });
    }

    function streamGroupNode(sink, streams) {
        return {
            id: "sink-" + sink.id + "-streams",
            aliases: ["streams", "apps", "applications"],
            title: qsTr("Streams"),
            subtitle: streams.length + " " + qsTr("active"),
            icon: "audio-x-generic-symbolic",
            iconColor: Config.styling.text1,
            template: "flat-action-group",
            groupOptions: { flattenAllChildrenOnParentMatch: true, maxNestedChildren: 8 },
            behavior: { filterable: true },
            children: streams.map(function(stream) { return volumeSliderNode(stream, true); })
        };
    }

    function muteSwitchActions(node) {
        return {
            toggle: { id: "toggle", title: qsTr("Toggle"), state: null, execute: function() { toggleMute(node); } },
            on: { id: "on", title: qsTr("On"), state: true, execute: function() { setMuted(node, true); } },
            off: { id: "off", title: qsTr("Off"), state: false, execute: function() { setMuted(node, false); } }
        };
    }

    function muteSwitchNode(node) {
        var muted = !!(node && node.audio && node.audio.muted);
        return {
            id: "mute",
            aliases: ["mute", "unmute", "toggle"],
            title: qsTr("Mute"),
            subtitle: muted ? qsTr("Muted") : qsTr("Unmuted"),
            icon: "audio-volume-muted-symbolic",
            iconColor: muted ? Config.styling.critical : Config.styling.text1,
            switchState: muted,
            control: { kind: "switch", target: "pipewire-mute", nodeId: node ? node.id : "" },
            switchActions: muteSwitchActions(node)
        };
    }

    function volumeSliderNode(node, stream) {
        var percent = node && node.audio ? Math.round((node.audio.volume || 0) * 100) : 0;
        return {
            id: stream ? "stream-" + node.id : "volume",
            aliases: stream ? ["stream", "volume", streamName(node)] : ["volume", "level", "slider"],
            title: stream ? streamName(node) : qsTr("Volume"),
            subtitle: percent + "%",
            icon: volumeIconName(node),
            iconColor: node && node.audio && node.audio.muted ? Config.styling.critical : Config.styling.secondaryAccent,
            control: { kind: "slider", target: "pipewire", nodeId: node ? node.id : "", from: 0, to: 150, step: 5, value: percent }
        };
    }

    function audioNodes(type) {
        var out = [];
        for (const node of Pipewire.nodes.values || []) {
            if ((node.type & type) === type)
                out.push(node);
        }
        return out;
    }

    function outputStreamsForSink(sink) {
        return audioNodes(PwNodeType.AudioOutStream).filter(function(stream) {
            for (const link of Pipewire.linkGroups.values || []) {
                if (link.source && link.target && link.source.id === stream.id && link.target.id === sink.id)
                    return true;
            }
            return false;
        });
    }

    function nodeTitle(node) {
        return node ? (node.description || node.name || qsTr("Unknown output")) : qsTr("Unknown output");
    }

    function volumeIconName(node) {
        var vol = node && node.audio ? node.audio.volume || 0.0 : 0.0;
        var muted = node && node.audio ? node.audio.muted || false : false;

        if (muted || vol <= 0.001)
            return "audio-volume-muted-symbolic";
        if (vol < 0.34)
            return "audio-volume-low-symbolic";
        if (vol < 0.67)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function streamName(stream) {
        var props = stream && stream.properties || {};
        return props["media.name"] || props["application.name"] || nodeTitle(stream);
    }

    function dashboardTabNodes() {
        var tabs = (shellScreenState && shellScreenState.dashboardTabs) || ["overview", "audio", "notifications", "bluetooth", "wifi", "energy", "stats"];
        return tabs.map(function(tab) { return actionNode({
            id: tab,
            title: tab,
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
        case "audio": return audioIconName();
        case "notifications": return NotificationCenter.doNotDisturbEnabled ? "bell-disabled-symbolic" : "bell-symbolic";
        case "bluetooth": return bluetoothIconName();
        case "wifi": return networkIconName();
        case "energy": return energyIconName();
        case "stats": return "utilities-system-monitor-symbolic";
        default: return "view-grid-symbolic";
        }
    }

    function colorForDashboardTab(tab) {
        switch (tab) {
        case "overview": return overviewIconColor();
        case "audio": return audioIconColor();
        case "notifications": return notificationIconColor();
        case "bluetooth": return bluetoothIconColor();
        case "wifi": return Config.styling.text0;
        case "energy": return energyIconColor();
        case "stats": return statsIconColor();
        default: return overviewIconColor();
        }
    }

    function overviewIconColor() {
        var sink = Pipewire.defaultAudioSink;
        var battery = UPower.displayDevice;
        var muted = (sink && sink.audio && sink.audio.muted) || false;
        var batteryCritical = !!battery && battery.isLaptopBattery === true && (battery.percentage || 0) <= 0.1;
        var networkOffline = !NetworkService.connectedSsid && !NetworkService.hasWiredConnection;

        if (NotificationCenter.hasCritical || batteryCritical)
            return Config.styling.critical;
        if (muted || networkOffline)
            return Config.styling.warning;
        return Config.styling.primaryAccent;
    }

    function audioIconName() {
        var sink = Pipewire.defaultAudioSink;
        var vol = sink && sink.audio ? sink.audio.volume || 0.0 : 0.0;
        var muted = sink && sink.audio ? sink.audio.muted || false : false;

        if (muted || vol <= 0.001)
            return "audio-volume-muted-symbolic";
        if (vol < 0.34)
            return "audio-volume-low-symbolic";
        if (vol < 0.67)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function audioIconColor() {
        var sink = Pipewire.defaultAudioSink;
        var vol = sink && sink.audio ? sink.audio.volume || 0.0 : 0.0;
        var muted = sink && sink.audio ? sink.audio.muted || false : false;

        if (muted)
            return Config.styling.critical;
        if (vol === 0.0)
            return Config.styling.warning;
        return Config.styling.text0;
    }

    function notificationIconColor() {
        if (NotificationCenter.hasCritical)
            return Config.styling.critical;
        if (NotificationCenter.doNotDisturbEnabled)
            return Config.styling.warning;
        return Config.styling.text0;
    }

    function bluetoothIconName() {
        var adapter = Bluetooth.defaultAdapter;
        var connectedCount = adapter ? (adapter.devices.values || []).filter(function(device) { return device.connected; }).length : 0;

        if (!adapter)
            return "bluetooth-disabled";
        if (adapter.state === BluetoothAdapterState.Blocked)
            return "bluetooth-disabled";
        if (!adapter.enabled || adapter.state === BluetoothAdapterState.Disabled)
            return "bluetooth-disabled";
        if (connectedCount > 0)
            return "bluetooth-active";
        if (adapter.discovering)
            return "bluetooth-active";
        return "bluetooth-paired";
    }

    function bluetoothIconColor() {
        var adapter = Bluetooth.defaultAdapter;
        return adapter && adapter.enabled ? Config.styling.bluetooth : Config.styling.critical;
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

    function energyIconName() {
        var battery = UPower.displayDevice;
        var hasBattery = battery && battery.isLaptopBattery === true;

        if (hasBattery)
            return battery.iconName || "battery-missing-symbolic";

        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "power-profile-power-saver-symbolic";
        case PowerProfile.Performance:
            return "power-profile-performance-symbolic";
        default:
            return "power-profile-balanced-symbolic";
        }
    }

    function energyIconColor() {
        var battery = UPower.displayDevice;
        var hasBattery = battery && battery.isLaptopBattery === true;

        if (hasBattery) {
            var percentage = Math.round((battery.percentage || 0) * 100);
            if (percentage <= 10)
                return Config.styling.critical;
            if (percentage <= 20)
                return Config.styling.warning;
            return battery.state === UPowerDeviceState.Charging ? Config.styling.good : Config.styling.text0;
        }

        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return Config.styling.good;
        case PowerProfile.Performance:
            return Config.styling.critical;
        default:
            return Config.colors.yellow;
        }
    }

    function statsIconColor() {
        if (Stats.cpuPercent >= 90 || Stats.memoryPercent >= 90)
            return Config.styling.critical;
        if (Stats.cpuPercent >= 70 || Stats.memoryPercent >= 75)
            return Config.styling.warning;
        return Config.styling.text0;
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

    function setMuted(node, muted) {
        if (node && node.audio)
            node.audio.muted = muted;
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

    function toggleMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
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
