pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var backend: root

    property bool wifiEnabled: false
    property bool wifiHardwareEnabled: true
    property bool networkingEnabled: true
    property string connectivity: "none"
    property string connectedSsid: ""
    property string connectedAddress: ""
    property string wifiDeviceName: ""
    property bool hasWiredConnection: false
    property string wiredDeviceName: ""
    property string wiredAddress: ""

    readonly property bool available: wifiHardwareEnabled || hasWiredConnection
    readonly property bool connected: connectedSsid !== "" || hasWiredConnection
    readonly property bool online: connectivity === "full"
    readonly property bool scanning: false
    readonly property bool busy: false
    readonly property bool connecting: false
    readonly property bool wifiAvailable: wifiHardwareEnabled && wifiEnabled

    readonly property string state: {
        if (!available) return "unavailable";
        if (hasWiredConnection) return "wired";
        if (connectedSsid) return "wireless";
        if (wifiEnabled) return "disconnected";
        return "disabled";
    }

    readonly property string iconName: {
        if (hasWiredConnection)
            return "network-wired-symbolic";
        if (!wifiHardwareEnabled)
            return "network-wireless-disabled-symbolic";
        const connected = root.connectedNetwork;
        if (connected)
            return root.wifiIconName(connected);
        return wifiEnabled ? "network-wireless-offline-symbolic" : "network-wireless-disabled-symbolic";
    }

    readonly property color iconColor: connected ? Config.styling.primaryAccent : Config.styling.text1

    readonly property string label: "Network"
    readonly property string statusText: {
        if (hasWiredConnection) return "Wired";
        if (connectedSsid) return connectedSsid;
        if (wifiEnabled) return "No connection";
        return "Wi-Fi off";
    }

    readonly property var presentation: {
        return {
            icon: root.iconName,
            color: root.iconColor,
            label: root.label,
            status: root.statusText,
            state: root.state,
            available: root.available,
            enabled: root.wifiEnabled,
            connected: root.connected,
            online: root.online
        };
    }

    readonly property var networks: rNetworks
    readonly property var connectedNetwork: _findConnected()

    readonly property var connectedNetworks: rNetworks.filter(n => n.connected)
    readonly property var availableNetworks: rNetworks

    readonly property var wiredConnection: hasWiredConnection ? {
        id: "wired",
        name: wiredDeviceName,
        device: wiredDeviceName,
        address: wiredAddress,
        connected: true
    } : null

    function rawNetworkById(id) {
        for (const n of rNetworks) {
            if (n.id === id || n.ssid === id || n.bssid === id)
                return n;
        }
        return null;
    }

    property var _pendingScanCallback: null

    function _findConnected() {
        for (let i = 0; i < rNetworks.length; ++i) {
            if (rNetworks[i].connected)
                return rNetworks[i];
        }
        return null;
    }

    function _parseSignal(signalStr) {
        const num = parseInt(signalStr, 10);
        if (isNaN(num))
            return 0;
        return Math.max(0, Math.min(100, num)) / 100;
    }

    function _parseSecurity(secStr) {
        if (!secStr || secStr === "--")
            return "Open";
        return secStr;
    }

    function signalBucket(strength) {
        const normalized = Math.max(0, Math.min(1, strength || 0));
        const percent = Math.round(normalized * 100);
        if (percent === 0)
            return "none";
        if (percent < 25)
            return "weak";
        if (percent < 50)
            return "ok";
        if (percent < 75)
            return "good";
        return "excellent";
    }

    function wifiIconName(network) {
        return `network-wireless-signal-${signalBucket(network ? network.signalStrength : 0)}-symbolic`;
    }

    function securityNeedsPsk(security) {
        return security.includes("WPA") || security.includes("WPA2") || security.includes("SAE") || security.includes("wpa-psk") || security.includes("wpa2-psk") || security.includes("sae");
    }

    function isOpenNetwork(network) {
        return network && (network.security === "Open" || network.security === "--" || !network.security);
    }

    function wifiBand(frequency) {
        const mhz = parseInt(frequency || "0", 10);
        if (mhz >= 5925) return "6 GHz";
        if (mhz >= 5000) return "5 GHz";
        if (mhz >= 2400) return "2.4 GHz";
        return "unknown";
    }

    function wifiChannel(frequency) {
        const mhz = parseInt(frequency || "0", 10);
        if (mhz === 2484) return 14;
        if (mhz >= 2412 && mhz <= 2472) return Math.floor((mhz - 2407) / 5);
        if (mhz >= 5000 && mhz <= 5895) return Math.floor((mhz - 5000) / 5);
        if (mhz >= 5955 && mhz <= 7115) return Math.floor((mhz - 5950) / 5);
        return "unknown";
    }

    function connectivityLabel() {
        const conn = root.connectivity;
        if (conn === "full") return "Connected";
        if (conn === "portal") return "Captive portal";
        if (conn === "limited") return "Limited";
        if (conn === "none") return "No internet";
        return conn;
    }

    function primaryNetworkInfo(network) {
        if (!network) return "Network unavailable";
        return [
            `Frequency: ${network.frequency || "unknown"} MHz`,
            `Channel: ${wifiChannel(network.frequency)}`,
            `Band: ${wifiBand(network.frequency)}`
        ].join(" | ");
    }

    function advancedNetworkInfo(network) {
        if (!network) return "Network unavailable";
        return [
            `SSID: ${network.ssid || "unknown"}`,
            `BSSID: ${network.bssid || "unknown"}`
        ].join("\n");
    }

    function _splitEscaped(text, separator) {
        const result = [];
        let current = "";
        let escaped = false;

        for (let i = 0; i < text.length; ++i) {
            const ch = text[i];

            if (escaped) {
                current += ch;
                escaped = false;
                continue;
            }

            if (ch === "\\") {
                escaped = true;
                continue;
            }

            if (ch === separator) {
                result.push(current);
                current = "";
                continue;
            }

            current += ch;
        }

        result.push(current);
        return result;
    }

    function _syncConnectedState() {
        const connected = root.connectedNetwork;
        root.connectedSsid = connected ? connected.ssid : "";
        root.connectedAddress = connected ? connected.bssid : "";
    }

    function _parseNetworks(output) {
        const lines = output.trim().split("\n");
        const newMap = new Map();
        const result = [];

        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i];
            if (!line)
                continue;

            const parts = _splitEscaped(line, ":");
            if (parts.length < 6)
                continue;

            const active = parts[0] === "yes";
            const signal = _parseSignal(parts[1]);
            const freq = parts[2];
            const ssid = parts[3] || "Hidden network";
            const bssid = parts[4];
            const security = _parseSecurity(parts[5]);

            const key = `${freq}:${ssid}:${bssid}`;
            newMap.set(key, true);

            const existing = rNetworks.find(n => `${n.frequency}:${n.ssid}:${n.bssid}` === key);
            if (existing) {
                existing.connected = active;
                existing.signalStrength = signal;
                existing.frequency = freq;
                existing.ssid = ssid;
                existing.bssid = bssid;
                existing.security = security;
                result.push(existing);
            } else {
                const id = `wifi-${bssid || freq}-${ssid}`;
                result.push({
                    id: id,
                    connected: active,
                    signalStrength: signal,
                    frequency: freq,
                    ssid: ssid,
                    bssid: bssid,
                    security: security,
                    name: ssid,
                    known: false,
                    secured: security !== "Open" && security !== "--",
                    strength: Math.round(signal * 100),
                    band: wifiBand(freq),
                    channel: wifiChannel(freq),
                    iconName: root.wifiIconName({ signalStrength: signal }),
                    statusText: active ? "Connected" : (security !== "Open" ? "Secured" : "Open")
                });
            }
        }

        for (let i = rNetworks.length - 1; i >= 0; --i) {
            const rn = rNetworks[i];
            const key = `${rn.frequency}:${rn.ssid}:${rn.bssid}`;
            if (!newMap.has(key)) {
                rNetworks.splice(i, 1);
            }
        }

        rNetworks = result;
        _syncConnectedState();
    }

    function _updateConnectivity(output) {
        const trimmed = output.trim();
        const values = trimmed.includes(":") ? trimmed.split(":") : trimmed.split("\n");
        root.wifiHardwareEnabled = values.length > 0 ? values[0].trim() === "enabled" : true;
        root.wifiEnabled = values.length > 1 ? values[1].trim() === "enabled" : false;
    }

    function _updateNetworkingState(output) {
        const value = output.trim().toLowerCase();
        root.networkingEnabled = value === "enabled";
    }

    function _updateGeneral(output) {
        root.connectivity = output.trim() || "none";
    }

    function _checkWiredConnection() {
        wiredCheckProcess.exec({
            command: ["nmcli", "-g", "DEVICE,TYPE,STATE,IP4.ADDRESS", "device", "status"]
        });
    }

    function _refreshAll() {
        networkingStateProcess.exec({ command: ["nmcli", "networking"] });
        statusProcess.exec({ command: ["nmcli", "-g", "WIFI-HW,WIFI", "radio"] });
        generalProcess.exec({ command: ["nmcli", "-g", "CONNECTIVITY", "general"] });
        getNetworksProcess.exec({ command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "wifi"] });
        root._checkWiredConnection();
    }

    property var rNetworks: []

    function setNetworkingEnabled(value) {
        const cmd = value ? "on" : "off";
        nmcliNetworkingProcess.exec({ command: ["nmcli", "networking", cmd] });
    }

    function scan(callback) {
        root._pendingScanCallback = callback;
        rescanProcess.exec({ command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes" ] });
    }

    function connectNetwork(id, options) {
        const network = rawNetworkById(id);
        const ssid = network ? network.ssid : id;
        const password = options?.password || "";
        const args = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password)
            args.push("password", password);
        connectProcess.exec({ command: args });
    }

    function disconnectNetwork(id) {
        const network = rawNetworkById(id);
        if (network && network.connected) {
            if (wifiDeviceName)
                disconnectProcess.exec({ command: ["nmcli", "dev", "disconnect", wifiDeviceName] });
        }
    }

    function refresh() {
        root._refreshAll();
    }

    function rescan(callback) {
        root._pendingScanCallback = callback;
        rescanProcess.exec({ command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"] });
    }

    function connectToNetwork(ssid, password) {
        const args = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password)
            args.push("password", password);
        connectProcess.exec({ command: args });
    }

    function disconnectDevice(deviceName) {
        if (deviceName)
            disconnectProcess.exec({ command: ["nmcli", "dev", "disconnect", deviceName] });
    }

    function disconnectWifi() {
        disconnectDevice(root.wifiDeviceName);
    }

    function disconnectWired() {
        disconnectDevice(root.wiredDeviceName);
    }

    function forgetNetwork(uuid) {
        if (uuid) {
            forgetProcess.exec({ command: ["nmcli", "con", "delete", "uuid", uuid] });
        }
    }

    function setWifiEnabled(enabled) {
        const cmd = enabled ? "on" : "off";
        wifiToggleProcess.exec({ command: ["nmcli", "radio", "wifi", cmd] });
    }

    function toggleWifi() {
        setWifiEnabled(!wifiEnabled);
    }

    Process {
        id: networkingStateProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._updateNetworkingState(text)
        }
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._updateConnectivity(text)
        }
    }

    Process {
        id: generalProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._updateGeneral(text)
        }
    }

    Process {
        id: rescanProcess
        function onExited(exitCode) {
            if (exitCode === 0) {
                getNetworksProcess.exec({ command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "wifi"] });
            } else if (root._pendingScanCallback) {
                root._pendingScanCallback(false);
                root._pendingScanCallback = null;
            }
        }
    }

    Process {
        id: getNetworksProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root._parseNetworks(text);
                if (root._pendingScanCallback) {
                    root._pendingScanCallback(true);
                    root._pendingScanCallback = null;
                }
            }
        }
    }

    Process {
        id: wiredCheckProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let foundWired = false;
                let wifiName = "";
                let wiredName = "";
                let wiredAddr = "";

                for (let i = 0; i < lines.length; ++i) {
                    const line = lines[i];
                    const parts = line.split(":");
                    if (parts.length >= 3) {
                        const device = parts[0];
                        const type = parts[1];
                        const state = parts[2];
                        const address = parts[3] || "";

                        if (type === "wifi" && state === "connected") {
                            wifiName = device;
                        } else if (type === "ethernet" && state === "connected" && !foundWired) {
                            foundWired = true;
                            wiredName = device;
                            wiredAddr = address;
                        }
                    }
                }

                root.hasWiredConnection = foundWired;
                root.wifiDeviceName = wifiName;
                root.wiredDeviceName = wiredName;
                root.wiredAddress = wiredAddr;
            }
        }
    }

    Process {
        id: monitorProcess
        stdout: SplitParser {
            onRead: {
                monitorDebounce.restart();
            }
        }
        function onExited(exitCode, exitStatus) {
            monitorRestartTimer.start();
        }
    }

    Process {
        id: nmcliNetworkingProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: connectProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: disconnectProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: forgetProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: wifiToggleProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Timer {
        id: monitorDebounce
        interval: 300
        onTriggered: {
            root._refreshAll();
        }
    }

    Timer {
        id: monitorRestartTimer
        interval: 2000
        onTriggered: {
            monitorProcess.exec({ command: ["nmcli", "monitor"] });
        }
    }

    Timer {
        id: initTimer
        interval: 100
        onTriggered: {
            root._refreshAll();
            monitorProcess.exec({ command: ["nmcli", "monitor"] });
        }
    }

    Component.onCompleted: {
        initTimer.start();
    }
}
