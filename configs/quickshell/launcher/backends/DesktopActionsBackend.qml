import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import qs.services

TreeBackendBase {
    id: root

    property var shellScreenState: null
    category: qsTr("Desktop Actions")

    backendId: "desktop-actions"
    name: qsTr("Desktop Actions")
    helpTitle: qsTr("Desktop Actions")
    helpDescription: qsTr("Run networking, session, system, and dashboard actions")
    helpIcon: "system-run"
    helpPrefixes: [":", "!"]
    priority: 120
    maxResults: 8
    dynamicCompositeRoot: true
    routes: [
        { pattern: "^[:!]\\s?(.*)", mode: "participate" },
        { pattern: "^.*$", mode: "ambient" }
    ]

    FlatActionGroupNode {
        name: "newxos"
        aliases: ["newxos", "nx", "repo"]
        title: qsTr("Newxos")
        icon: "nix-snowflake-symbolic"
        groupOptions: ({
            breadcrumbMode: "always",
            flattenAllChildrenOnParentMatch: true,
            maxNestedChildren: 5
        })
        actionId: "newxos-switch"
        action: function() { launchTerminalPaused(qsTr("newxos switch"), "newxos switch"); }

        ActionNode {
            name: "switch"
            aliases: ["switch", "rebuild"]
            title: qsTr("Switch System")
            subtitle: qsTr("Run newxos switch")
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
            name: "devmode"
            aliases: ["dev", "devmode", "dev-mode"]
            title: qsTr("Dev Mode")
            subtitle: qsTr("Switch between default and dev specialization")
            icon: "applications-development-symbolic"
            iconColor: Config.styling.urgent
            switchState: isDevMode()

            SwitchActionNode {
                aliases: ["no"]
                state: true
                actionId: "newxos-devmode"
                action: function() { setDevMode(true); }
            }

            SwitchActionNode {
                aliases: ["nf"]
                state: false
                actionId: "newxos-devmode"
                action: function() { setDevMode(false); }
            }

            SwitchActionNode {
                aliases: ["nt"]
                state: null
                actionId: "newxos-devmode"
                action: function() { setDevMode(null); }
            }
        }
    }

    FlatActionGroupNode {
        name: "session"
        aliases: ["session", "system"]
        title: qsTr("Session")
        icon: "system-shutdown-symbolic"
        groupOptions: ({
            breadcrumbMode: "always",
            flattenAllChildrenOnParentMatch: true,
            maxNestedChildren: 5
        })

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
        dynamicChildren: dashboardTabNodes()
        actionId: "dashboard"
        actionProps: ({ tab: "overview" })
        action: function() {
            if (shellScreenState)
                shellScreenState.openDashboard("overview");
        }
    }

    ActionGroupNode {
        name: "network"
        aliases: ["net", "network", "networking"]
        title: qsTr("Networking")
        icon: "network-wireless-symbolic"
        iconColor: Config.styling.primaryAccent
        SwitchNode {
            name: "wifi"
            aliases: ["wifi", "wi-fi"]
            title: qsTr("Wi-Fi")
            icon: "network-wireless-symbolic"
            iconColor: NetworkService.wifiEnabled ? Config.styling.primaryAccent : Config.styling.text1
            switchState: NetworkService.wifiEnabled

            SwitchActionNode {
                aliases: ["wo"]
                state: true
                actionId: "wifi"
                action: function() { setWifi(true); }
            }

            SwitchActionNode {
                aliases: ["wf"]
                state: false
                actionId: "wifi"
                action: function() { setWifi(false); }
            }

            SwitchActionNode {
                aliases: ["wt"]
                state: null
                actionId: "wifi"
                action: function() { setWifi(null); }
            }
        }

        SwitchNode {
            name: "vpn"
            aliases: ["vpn", "nordvpn"]
            title: qsTr("VPN")
            icon: "network-vpn-symbolic"
            iconColor: NordVPN.connected || NordVPN.connecting ? Config.styling.good : Config.styling.warning
            switchState: NordVPN.connected || NordVPN.connecting

            ActionNode {
                name: "connect"
                aliases: ["connect"]
                title: qsTr("Connect")
                icon: "network-vpn-symbolic"
                iconColor: Config.styling.good
                dynamicChildren: buildVpnConnectChildren()
                actionId: "vpn"
                actionProps: ({ state: "connect" })
                action: function() { NordVPN.connect(null); }
            }

            ActionNode {
                name: "disconnect"
                aliases: ["disconnect"]
                title: qsTr("Disconnect")
                icon: "network-vpn-disconnected-symbolic"
                iconColor: Config.styling.warning
                actionId: "vpn"
                actionProps: ({ state: "disconnect" })
                action: function() { NordVPN.disconnect(); }
            }

            ActionNode {
                name: "toggle"
                aliases: ["toggle"]
                title: qsTr("Toggle")
                subtitle: qsTr("Connect or disconnect VPN")
                icon: "view-refresh-symbolic"
                iconColor: Config.styling.primaryAccent
                actionId: "vpn"
                actionProps: ({ state: null })
                action: function() {
                    if (NordVPN.connected || NordVPN.connecting)
                        NordVPN.disconnect();
                    else
                        NordVPN.connect(null);
                }
            }

            SwitchNode {
                name: "autoconnect"
                aliases: ["autoconnect", "auto-connect"]
                title: qsTr("Auto-connect")
                icon: "network-vpn-symbolic"
                iconColor: NordVPN.settings && NordVPN.settings["Auto-connect"] ? Config.styling.good : Config.styling.text1
                switchState: NordVPN.settings && NordVPN.settings["Auto-connect"]

                SwitchActionNode {
                    aliases: ["ao"]
                    state: true
                    actionId: "vpn-autoconnect"
                    action: function() { NordVPN.setSetting("autoconnect", true); }
                }

                SwitchActionNode {
                    aliases: ["af"]
                    state: false
                    actionId: "vpn-autoconnect"
                    action: function() { NordVPN.setSetting("autoconnect", false); }
                }

                SwitchActionNode {
                    aliases: ["at"]
                    state: null
                    actionId: "vpn-autoconnect"
                    action: function() { NordVPN.setSetting("autoconnect", !(NordVPN.settings && NordVPN.settings["Auto-connect"])); }
                }
            }

            SwitchNode {
                name: "killswitch"
                aliases: ["killswitch", "kill-switch"]
                title: qsTr("Kill Switch")
                icon: "network-vpn-symbolic"
                iconColor: NordVPN.settings && NordVPN.settings["Kill Switch"] ? Config.styling.critical : Config.styling.text1
                switchState: NordVPN.settings && NordVPN.settings["Kill Switch"]

                SwitchActionNode {
                    aliases: ["ko"]
                    state: true
                    actionId: "vpn-killswitch"
                    action: function() { NordVPN.setSetting("killswitch", true); }
                }

                SwitchActionNode {
                    aliases: ["kf"]
                    state: false
                    actionId: "vpn-killswitch"
                    action: function() { NordVPN.setSetting("killswitch", false); }
                }

                SwitchActionNode {
                    aliases: ["kt"]
                    state: null
                    actionId: "vpn-killswitch"
                    action: function() { NordVPN.setSetting("killswitch", !(NordVPN.settings && NordVPN.settings["Kill Switch"])); }
                }
            }
        }

        SwitchNode {
            name: "bluetooth"
            aliases: ["bt", "bluetooth"]
            title: qsTr("Bluetooth")
            icon: "bluetooth-symbolic"
            iconColor: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Config.styling.bluetooth : Config.styling.text1
            switchState: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : null

            SwitchActionNode {
                aliases: ["bo"]
                state: true
                actionId: "bluetooth"
                action: function() { setBluetooth(true); }
            }

            SwitchActionNode {
                aliases: ["bf"]
                state: false
                actionId: "bluetooth"
                action: function() { setBluetooth(false); }
            }

            SwitchActionNode {
                aliases: ["btt"]
                state: null
                actionId: "bluetooth"
                action: function() { setBluetooth(null); }
            }
        }
    }

    ActionGroupNode {
        name: "audio"
        aliases: ["audio", "sound"]
        title: qsTr("Audio")
        icon: "audio-volume-high-symbolic"
        iconColor: Config.styling.secondaryAccent
        ActionNode {
            name: "mute"
            aliases: ["mute"]
            title: qsTr("Toggle Mute")
            subtitle: qsTr("Mute or unmute the default output")
            icon: "audio-volume-muted-symbolic"
            iconColor: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? Config.styling.critical : Config.styling.secondaryAccent
            actionId: "mute"
            action: function() { toggleMute(Pipewire.defaultAudioSink); }
        }

        ActionNode {
            name: "mic"
            aliases: ["mic", "microphone"]
            title: qsTr("Toggle Microphone Mute")
            subtitle: qsTr("Mute or unmute the default input")
            icon: "microphone-sensitivity-muted-symbolic"
            iconColor: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted ? Config.styling.critical : Config.styling.secondaryAccent
            actionId: "mic"
            action: function() { toggleMute(Pipewire.defaultAudioSource); }
        }
    }

    ActionGroupNode {
        name: "notifications"
        aliases: ["notif", "notifications", "notification"]
        title: qsTr("Notifications")
        icon: "bell-symbolic"
        iconColor: Config.styling.warning
        SwitchNode {
            name: "dnd"
            aliases: ["dnd"]
            title: qsTr("Do Not Disturb")
            icon: "bell-disabled-symbolic"
            iconColor: NotificationCenter.doNotDisturbEnabled ? Config.styling.warning : Config.styling.text1
            switchState: NotificationCenter.doNotDisturbEnabled

            SwitchActionNode {
                aliases: ["do"]
                state: true
                actionId: "dnd"
                action: function() { setDnd(true); }
            }

            SwitchActionNode {
                aliases: ["df"]
                state: false
                dangerousOff: false
                actionId: "dnd"
                action: function() { setDnd(false); }
            }

            SwitchActionNode {
                aliases: ["dt"]
                state: null
                actionId: "dnd"
                action: function() { setDnd(null); }
            }
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

    ActionGroupNode {
        name: "power"
        aliases: ["power", "energy"]
        title: qsTr("Power")
        icon: "battery-symbolic"
        iconColor: Config.styling.good
        ActionGroupNode {
            name: "powermode"
            aliases: ["powermode", "power-mode", "profile"]
            title: qsTr("Power Mode")
            icon: "power-profile-balanced-symbolic"
            iconColor: Config.styling.urgent

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
            children.push(actionNode({
                id: "group-" + group,
                title: group,
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

    function dashboardTabNodes() {
        var tabs = shellScreenState ? shellScreenState.dashboardTabs : ["overview", "audio", "notifications", "bluetooth", "wifi", "energy", "stats"];
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
        Quickshell.execDetached({ command: ["sh", "-lc", "exec \"${TERMINAL:-kitty}\" -e sh -lc \"$1\"", "launcher-terminal", command] });
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
