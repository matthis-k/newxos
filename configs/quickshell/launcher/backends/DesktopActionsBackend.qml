import QtQml
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

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
    helpDescription: qsTr("Run networking, session, system, and dashboard actions")
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

    property var actionTree: computeActionTree()

    function computeActionTree() {
        var vpnConnectChildren = buildVpnConnectChildren();

        return [
            // Dashboard
            {
                id: "dashboard",
                aliases: ["db", "dashboard"],
                title: qsTr("Dashboard"),
                icon: "view-dashboard-symbolic",
                defaultAction: {
                    actionId: "dashboard", tab: "overview",
                    execute: function() {
                        if (shellScreenState)
                            shellScreenState.openDashboard("overview");
                    }
                },
                children: dashboardTabNodes()
            },

            // Networking
            {
                id: "network",
                aliases: ["net", "network", "networking"],
                title: qsTr("Networking"),
                icon: "network-wireless-symbolic",
                children: [
                    {
                        id: "networking",
                        aliases: ["networking"],
                        title: qsTr("Toggle Networking"),
                        subtitle: qsTr("Enable or disable all network interfaces"),
                        icon: "network-wireless-symbolic",
                        children: stateNodes("networking", function(state) { setNetworking(state); })
                    },
                    {
                        id: "wifi",
                        aliases: ["wifi", "wi-fi"],
                        title: qsTr("Wi-Fi"),
                        icon: "network-wireless-symbolic",
                        children: stateNodes("wifi", function(state) { setWifi(state); })
                    },
                    {
                        id: "vpn",
                        aliases: ["vpn", "nordvpn"],
                        title: qsTr("VPN"),
                        icon: "network-vpn-symbolic",
                        children: [
                            {
                                id: "connect",
                                aliases: ["connect"],
                                title: qsTr("Connect"),
                                icon: "network-vpn-symbolic",
                                defaultAction: {
                                    actionId: "vpn", state: "connect",
                                    execute: function() { NordVPN.connect(null); }
                                },
                                children: vpnConnectChildren
                            },
                            {
                                id: "disconnect",
                                aliases: ["disconnect"],
                                title: qsTr("Disconnect"),
                                icon: "network-vpn-disconnected-symbolic",
                                action: {
                                    actionId: "vpn", state: "disconnect",
                                    execute: function() { NordVPN.disconnect(); }
                                }
                            },
                            {
                                id: "toggle",
                                aliases: ["toggle"],
                                title: qsTr("Toggle"),
                                subtitle: qsTr("Connect or disconnect VPN"),
                                icon: "view-refresh-symbolic",
                                action: {
                                    actionId: "vpn", state: null,
                                    execute: function() {
                                        if (NordVPN.connected || NordVPN.connecting)
                                            NordVPN.disconnect();
                                        else
                                            NordVPN.connect(null);
                                    }
                                }
                            },
                            {
                                id: "autoconnect",
                                aliases: ["autoconnect", "auto-connect"],
                                title: qsTr("Auto-connect"),
                                icon: "network-vpn-symbolic",
                                children: stateNodes("vpn-autoconnect", function(state) { setVpnAutoConnect(state); })
                            },
                            {
                                id: "killswitch",
                                aliases: ["killswitch", "kill-switch"],
                                title: qsTr("Kill Switch"),
                                icon: "network-vpn-symbolic",
                                children: stateNodes("vpn-killswitch", function(state) { setVpnKillSwitch(state); })
                            }
                        ]
                    },
                    {
                        id: "bluetooth",
                        aliases: ["bt", "bluetooth"],
                        title: qsTr("Bluetooth"),
                        icon: "bluetooth-symbolic",
                        children: stateNodes("bluetooth", function(state) { setBluetooth(state); })
                    }
                ]
            },

            // Audio
            {
                id: "audio",
                aliases: ["audio", "sound"],
                title: qsTr("Audio"),
                icon: "audio-volume-high-symbolic",
                children: [
                    {
                        id: "mute",
                        aliases: ["mute"],
                        title: qsTr("Toggle Mute"),
                        subtitle: qsTr("Mute or unmute the default output"),
                        icon: "audio-volume-muted-symbolic",
                        action: {
                            actionId: "mute",
                            execute: function() { toggleMute(Pipewire.defaultAudioSink); }
                        }
                    },
                    {
                        id: "mic",
                        aliases: ["mic", "microphone"],
                        title: qsTr("Toggle Microphone Mute"),
                        subtitle: qsTr("Mute or unmute the default input"),
                        icon: "microphone-sensitivity-muted-symbolic",
                        action: {
                            actionId: "mic",
                            execute: function() { toggleMute(Pipewire.defaultAudioSource); }
                        }
                    }
                ]
            },

            // Notifications
            {
                id: "notifications",
                aliases: ["notif", "notifications", "notification"],
                title: qsTr("Notifications"),
                icon: "bell-symbolic",
                children: [
                    {
                        id: "dnd",
                        aliases: ["dnd"],
                        title: qsTr("Do Not Disturb"),
                        icon: "bell-disabled-symbolic",
                        children: stateNodes("dnd", function(state) { setDnd(state); })
                    },
                    {
                        id: "clear",
                        aliases: ["clear", "clear-all"],
                        title: qsTr("Clear All"),
                        subtitle: qsTr("Dismiss all current notifications"),
                        icon: "user-trash-symbolic",
                        action: {
                            actionId: "clear-notifications",
                            execute: function() { NotificationCenter.clearAll(); }
                        }
                    }
                ]
            },

            // Power
            {
                id: "power",
                aliases: ["power", "energy"],
                title: qsTr("Power"),
                icon: "battery-symbolic",
                children: [
                    {
                        id: "powermode",
                        aliases: ["powermode", "power-mode", "profile"],
                        title: qsTr("Power Mode"),
                        icon: "power-profile-balanced-symbolic",
                        children: [
                            {
                                id: "powersaver",
                                aliases: ["powersaver", "power-saver", "save"],
                                title: qsTr("Power Saver"),
                                icon: "power-profile-power-saver-symbolic",
                                action: {
                                    actionId: "powermode", mode: PowerProfile.PowerSaver,
                                    execute: function() { PowerProfiles.profile = PowerProfile.PowerSaver; }
                                }
                            },
                            {
                                id: "balanced",
                                aliases: ["balanced", "balance"],
                                title: qsTr("Balanced"),
                                icon: "power-profile-balanced-symbolic",
                                action: {
                                    actionId: "powermode", mode: PowerProfile.Balanced,
                                    execute: function() { PowerProfiles.profile = PowerProfile.Balanced; }
                                }
                            },
                            {
                                id: "performance",
                                aliases: ["performance", "perf", "high"],
                                title: qsTr("Performance"),
                                icon: "power-profile-performance-symbolic",
                                action: {
                                    actionId: "powermode", mode: PowerProfile.Performance,
                                    execute: function() { PowerProfiles.profile = PowerProfile.Performance; }
                                }
                            }
                        ]
                    }
                ]
            },

            // Screenshot
            {
                id: "screenshot",
                aliases: ["ss", "screenshot"],
                title: qsTr("Screenshot"),
                icon: "camera-photo-symbolic",
                children: [
                    {
                        id: "area",
                        aliases: ["area", "region"],
                        title: qsTr("Area"),
                        subtitle: qsTr("Capture a selected region"),
                        icon: "image-region-symbolic",
                        action: {
                            actionId: "screenshot", mode: "area",
                            execute: function() { screenshotArea(); }
                        }
                    },
                    {
                        id: "window",
                        aliases: ["window"],
                        title: qsTr("Window"),
                        subtitle: qsTr("Capture the active window"),
                        icon: "window-symbolic",
                        action: {
                            actionId: "screenshot", mode: "window",
                            execute: function() { screenshotWindow(); }
                        }
                    },
                    {
                        id: "screen",
                        aliases: ["screen", "full", "display"],
                        title: qsTr("Screen"),
                        subtitle: qsTr("Capture all displays"),
                        icon: "video-display-symbolic",
                        action: {
                            actionId: "screenshot", mode: "screen",
                            execute: function() { screenshotScreen(); }
                        }
                    },
                    {
                        id: "read",
                        aliases: ["read", "ocr", "text"],
                        title: qsTr("Read"),
                        subtitle: qsTr("Capture area and extract text (OCR)"),
                        icon: "text-editor-symbolic",
                        action: {
                            actionId: "screenshot", mode: "read",
                            execute: function() { screenshotRead(); }
                        }
                    },
                    {
                        id: "annotate",
                        aliases: ["annotate", "edit", "satty"],
                        title: qsTr("Annotate"),
                        subtitle: qsTr("Capture area and annotate with satty"),
                        icon: "image-x-generic-symbolic",
                        action: {
                            actionId: "screenshot", mode: "annotate",
                            execute: function() { screenshotAnnotate(); }
                        }
                    }
                ]
            },

            // Session
            {
                id: "session",
                aliases: ["session", "system"],
                title: qsTr("Session"),
                icon: "system-shutdown-symbolic",
                children: [
                    {
                        id: "lock",
                        aliases: ["lock"],
                        title: qsTr("Lock"),
                        subtitle: qsTr("Lock the current session"),
                        icon: "system-lock-screen-symbolic",
                        action: {
                            actionId: "lock",
                            execute: function() { Quickshell.execDetached({ command: ["loginctl", "lock-session"] }); }
                        }
                    },
                    {
                        id: "logout",
                        aliases: ["logout", "exit"],
                        title: qsTr("Log Out"),
                        subtitle: qsTr("Exit the current Hyprland session"),
                        icon: "system-log-out-symbolic",
                        action: {
                            actionId: "logout",
                            execute: function() { Quickshell.execDetached({ command: ["hyprctl", "dispatch", "exit"] }); }
                        },
                        dangerous: true
                    },
                    {
                        id: "shutdown",
                        aliases: ["shutdown", "poweroff", "power-off"],
                        title: qsTr("Shut Down"),
                        subtitle: qsTr("Power off this machine"),
                        icon: "system-shutdown-symbolic",
                        action: {
                            actionId: "shutdown",
                            execute: function() { Quickshell.execDetached({ command: ["systemctl", "poweroff"] }); }
                        },
                        dangerous: true
                    },
                    {
                        id: "reboot",
                        aliases: ["reboot", "restart"],
                        title: qsTr("Reboot"),
                        subtitle: qsTr("Restart this machine"),
                        icon: "system-reboot-symbolic",
                        action: {
                            actionId: "reboot",
                            execute: function() { Quickshell.execDetached({ command: ["systemctl", "reboot"] }); }
                        },
                        dangerous: true
                    }
                ]
            }
        ];
    }

    function buildVpnConnectChildren() {
        var children = [];

        children.push({
            id: "fastest",
            title: qsTr("Fastest server"),
            icon: "network-vpn-symbolic",
            action: {
                actionId: "vpn", state: "connect",
                execute: function() { NordVPN.connect(null); }
            }
        });

        (NordVPN.countries || []).forEach(function(country) {
            children.push({
                id: "country-" + country,
                title: country,
                subtitle: qsTr("Country"),
                icon: "network-vpn-symbolic",
                action: {
                    actionId: "vpn", state: "connect", destination: country,
                    execute: function() { NordVPN.connect(country); }
                }
            });
        });

        (NordVPN.groups || []).forEach(function(group) {
            children.push({
                id: "group-" + group,
                title: group,
                subtitle: qsTr("Group"),
                icon: "network-vpn-symbolic",
                action: {
                    actionId: "vpn", state: "connect", destination: group,
                    execute: function() { NordVPN.connect(group); }
                }
            });
        });

        return children;
    }

    function dashboardTabNodes() {
        var tabs = shellScreenState ? shellScreenState.dashboardTabs : ["overview", "audio", "notifications", "bluetooth", "wifi", "energy", "stats"];
        return tabs.map(function(tab) { return {
            id: tab,
            title: tab,
            icon: "view-dashboard-symbolic",
            action: {
                actionId: "dashboard", tab: tab,
                execute: function() {
                    if (shellScreenState)
                        shellScreenState.openDashboard(tab);
                }
            }
        }; });
    }

    function stateNodes(actionId, executor) {
        return [
            {
                id: "on", title: qsTr("Turn On"), icon: "object-select-symbolic",
                action: { actionId: actionId, state: true, execute: function() { executor(true); } }
            },
            {
                id: "off", title: qsTr("Turn Off"), icon: "window-close-symbolic",
                action: { actionId: actionId, state: false, execute: function() { executor(false); } },
                dangerous: actionId !== "dnd"
            },
            {
                id: "toggle", title: qsTr("Toggle"), icon: "view-refresh-symbolic",
                action: { actionId: actionId, state: null, execute: function() { executor(null); } }
            }
        ];
    }

    function setWifi(state) {
        var enabled = state === null ? !NetworkService.wifiEnabled : state;
        Quickshell.execDetached({ command: ["nmcli", "radio", "wifi", enabled ? "on" : "off"] });
        NetworkService.refresh();
    }

    function setNetworking(state) {
        var enabled = state === null ? !NetworkService.networkingEnabled : state;
        Quickshell.execDetached({ command: ["nmcli", "networking", enabled ? "on" : "off"] });
        NetworkService.refresh();
    }

    function setBluetooth(state) {
        var adapter = Bluetooth.defaultAdapter;
        if (adapter)
            adapter.enabled = state === null ? !adapter.enabled : state;
    }

    function setVpnAutoConnect(state) {
        var current = NordVPN.settings && NordVPN.settings["Auto-connect"];
        var enabled = state === null ? !current : state;
        NordVPN.setSetting("autoconnect", !!enabled);
    }

    function setVpnKillSwitch(state) {
        var current = NordVPN.settings && NordVPN.settings["Kill Switch"];
        var enabled = state === null ? !current : state;
        NordVPN.setSetting("killswitch", !!enabled);
    }

    function setDnd(state) {
        var enabled = state === null ? !NotificationCenter.doNotDisturbEnabled : state;
        NotificationCenter.toastsEnabled = !enabled;
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
        Quickshell.execDetached({ command: ["screen-read-region"] });
    }

    function screenshotAnnotate() {
        Quickshell.execDetached({ command: ["screen-shot", "region"] });
    }

    function activate(result, action) {
        var metadata = result ? result.metadata || {} : {};
        if (metadata.kind === "completion" && metadata.replaceQuery)
            return;

        var cmdAction = (action && action.payload) || (metadata.action && metadata.action.payload) || metadata.action || {};
        if (typeof cmdAction.execute === "function")
            cmdAction.execute();
    }
}
