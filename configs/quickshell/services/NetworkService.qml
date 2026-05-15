pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiHardwareEnabled: true
    property string connectivity: "none"
    property string connectedSsid: ""
    property string connectedAddress: ""
    property bool hasWiredConnection: false
    property string wiredDeviceName: ""
    property string wiredAddress: ""

    readonly property var networks: rNetworks
    readonly property var connectedNetwork: _findConnected()

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
                result.push({
                    connected: active,
                    signalStrength: signal,
                    frequency: freq,
                    ssid: ssid,
                    bssid: bssid,
                    security: security,
                    name: ssid
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

    function _updateGeneral(output) {
        root.connectivity = output.trim() || "none";
    }

    function _checkWiredConnection() {
        wiredCheckProcess.exec({
            command: ["nmcli", "-g", "DEVICE,TYPE,STATE,IP4.ADDRESS", "device", "status"]
        });
    }

    function _refreshAll() {
        statusProcess.exec({ command: ["nmcli", "-g", "WIFI-HW,WIFI", "radio"] });
        generalProcess.exec({ command: ["nmcli", "-g", "CONNECTIVITY", "general"] });
        getNetworksProcess.exec({ command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "wifi"] });
        root._checkWiredConnection();
    }

    property var rNetworks: []

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

                        if (type === "ethernet" && state === "connected") {
                            foundWired = true;
                            wiredName = device;
                            wiredAddr = address;
                            break;
                        }
                    }
                }

                root.hasWiredConnection = foundWired;
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

    function disconnectNetwork() {
        if (root.connectedSsid) {
            disconnectProcess.exec({ command: ["nmcli", "con", "down", "id", root.connectedSsid] });
        } else if (root.hasWiredConnection) {
            disconnectProcess.exec({ command: ["nmcli", "con", "down", "id", root.wiredDeviceName] });
        }
    }

    function forgetNetwork(uuid) {
        if (uuid) {
            forgetProcess.exec({ command: ["nmcli", "con", "delete", "uuid", uuid] });
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
}
