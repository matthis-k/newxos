pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import "network"

Singleton {
    id: root

    readonly property var backend: root

    readonly property QtObject networkModels: NetworkModels {}

    readonly property QtObject networkPresentation: NetworkPresentation {}

    readonly property QtObject nmcliParser: NmcliParser {}

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
    property string currentOperationKind: ""
    property string currentOperationTarget: ""
    property bool currentOperationRunning: false
    property string currentOperationLastError: ""

    readonly property var operation: ({
            kind: currentOperationKind,
            target: currentOperationTarget,
            running: currentOperationRunning,
            lastError: currentOperationLastError
        })
    readonly property bool scanning: currentOperationRunning && currentOperationKind === "scan"
    readonly property bool busy: currentOperationRunning
    readonly property bool connecting: currentOperationRunning && currentOperationKind === "connect"
    readonly property bool wifiAvailable: wifiHardwareEnabled && wifiEnabled

    readonly property string state: {
        if (!available)
            return "unavailable";
        if (hasWiredConnection)
            return "wired";
        if (connectedSsid)
            return "wireless";
        if (wifiEnabled)
            return "disconnected";
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
        if (hasWiredConnection)
            return "Wired";
        if (connectedSsid)
            return connectedSsid;
        if (wifiEnabled)
            return "No connection";
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

    function beginOperation(kind, target) {
        currentOperationKind = kind || "";
        currentOperationTarget = target || "";
        currentOperationRunning = true;
        currentOperationLastError = "";
    }

    function finishOperation(success, message) {
        currentOperationRunning = false;
        currentOperationLastError = success ? "" : (message || `${currentOperationKind || "operation"} failed`);
    }

    function _findConnected() {
        for (let i = 0; i < rNetworks.length; ++i) {
            if (rNetworks[i].connected)
                return rNetworks[i];
        }
        return null;
    }

    function signalBucket(strength) {
        return networkPresentation.signalBucket(strength);
    }

    function wifiIconName(network) {
        return networkPresentation.wifiIconName(network);
    }

    function securityNeedsPsk(security) {
        return networkPresentation.securityNeedsPsk(security || "");
    }

    function isOpenNetwork(network) {
        return networkPresentation.isOpenNetwork(network);
    }

    function securityLabel(network) {
        return networkPresentation.securityLabel(network);
    }

    function wifiBand(frequency) {
        return networkPresentation.wifiBand(frequency);
    }

    function wifiChannel(frequency) {
        return networkPresentation.wifiChannel(frequency);
    }

    function connectivityLabel() {
        return networkPresentation.connectivityLabel(root.connectivity);
    }

    function primaryNetworkInfo(network) {
        return networkPresentation.primaryNetworkInfo(network);
    }

    function advancedNetworkInfo(network) {
        return networkPresentation.advancedNetworkInfo(network);
    }

    function _syncConnectedState() {
        const connected = root.connectedNetwork;
        root.connectedSsid = connected ? connected.ssid : "";
        root.connectedAddress = connected ? connected.bssid : "";
    }

    function _parseNetworks(output) {
        rNetworks = networkModels.mergeWifiNetworks(rNetworks, nmcliParser.parseWifiNetworks(output), networkPresentation);
        _syncConnectedState();
    }

    function _updateConnectivity(output) {
        const state = nmcliParser.parseRadioState(output);
        root.wifiHardwareEnabled = state.wifiHardwareEnabled;
        root.wifiEnabled = state.wifiEnabled;
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
        networkingStateProcess.exec({
            command: ["nmcli", "networking"]
        });
        statusProcess.exec({
            command: ["nmcli", "-g", "WIFI-HW,WIFI", "radio"]
        });
        generalProcess.exec({
            command: ["nmcli", "-g", "CONNECTIVITY", "general"]
        });
        getNetworksProcess.exec({
            command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "wifi"]
        });
        root._checkWiredConnection();
    }

    property var rNetworks: []

    function setNetworkingEnabled(value) {
        const cmd = value ? "on" : "off";
        beginOperation("toggle", "networking");
        nmcliNetworkingProcess.exec({
            command: ["nmcli", "networking", cmd]
        });
    }

    function scan(callback) {
        root._pendingScanCallback = callback;
        beginOperation("scan", "wifi");
        rescanProcess.exec({
            command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        });
    }

    function connectNetwork(id, options) {
        const network = rawNetworkById(id);
        const ssid = network ? network.ssid : id;
        const password = options?.password || "";
        const args = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password)
            args.push("password", password);
        beginOperation("connect", ssid);
        connectProcess.exec({
            command: args
        });
    }

    function disconnectNetwork(id) {
        const network = rawNetworkById(id);
        if (network && network.connected) {
            if (wifiDeviceName) {
                beginOperation("disconnect", network.ssid || id);
                disconnectProcess.exec({
                    command: ["nmcli", "dev", "disconnect", wifiDeviceName]
                });
            }
        }
    }

    function refresh() {
        root._refreshAll();
    }

    function rescan(callback) {
        scan(callback);
    }

    function connectToNetwork(ssid, password) {
        const args = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password)
            args.push("password", password);
        beginOperation("connect", ssid);
        connectProcess.exec({
            command: args
        });
    }

    function disconnectDevice(deviceName) {
        if (deviceName) {
            beginOperation("disconnect", deviceName);
            disconnectProcess.exec({
                command: ["nmcli", "dev", "disconnect", deviceName]
            });
        }
    }

    function disconnectWifi() {
        disconnectDevice(root.wifiDeviceName);
    }

    function disconnectWired() {
        disconnectDevice(root.wiredDeviceName);
    }

    function forgetNetwork(uuid) {
        if (uuid) {
            beginOperation("forget", uuid);
            forgetProcess.exec({
                command: ["nmcli", "con", "delete", "uuid", uuid]
            });
        }
    }

    function setWifiEnabled(enabled) {
        const cmd = enabled ? "on" : "off";
        beginOperation("toggle", "wifi");
        wifiToggleProcess.exec({
            command: ["nmcli", "radio", "wifi", cmd]
        });
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
                getNetworksProcess.exec({
                    command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "wifi"]
                });
            } else if (root._pendingScanCallback) {
                root.finishOperation(false, `scan failed (${exitCode})`);
                root._pendingScanCallback(false);
                root._pendingScanCallback = null;
            } else {
                root.finishOperation(false, `scan failed (${exitCode})`);
            }
        }
    }

    Process {
        id: getNetworksProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root._parseNetworks(text);
                if (root.currentOperationKind === "scan")
                    root.finishOperation(true, "");
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
                const state = nmcliParser.parseDeviceStatus(text);
                root.hasWiredConnection = state.hasWiredConnection;
                root.wifiDeviceName = state.wifiDeviceName;
                root.wiredDeviceName = state.wiredDeviceName;
                root.wiredAddress = state.wiredAddress;
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
            root.finishOperation(exitCode === 0, `networking toggle failed (${exitCode})`);
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: connectProcess
        function onExited(exitCode) {
            root.finishOperation(exitCode === 0, `connect failed (${exitCode})`);
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: disconnectProcess
        function onExited(exitCode) {
            root.finishOperation(exitCode === 0, `disconnect failed (${exitCode})`);
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: forgetProcess
        function onExited(exitCode) {
            root.finishOperation(exitCode === 0, `forget failed (${exitCode})`);
            if (exitCode === 0)
                root._refreshAll();
        }
    }

    Process {
        id: wifiToggleProcess
        function onExited(exitCode) {
            root.finishOperation(exitCode === 0, `wifi toggle failed (${exitCode})`);
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
            monitorProcess.exec({
                command: ["nmcli", "monitor"]
            });
        }
    }

    Timer {
        id: initTimer
        interval: 100
        onTriggered: {
            root._refreshAll();
            monitorProcess.exec({
                command: ["nmcli", "monitor"]
            });
        }
    }

    Component.onCompleted: {
        initTimer.start();
    }
}
