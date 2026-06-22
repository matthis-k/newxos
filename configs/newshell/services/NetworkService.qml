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

    property var _pendingScanCallback: null

    function rawNetworkById(id) {
        for (const n of rNetworks) {
            if (n.id === id || n.ssid === id || n.bssid === id)
                return n;
        }
        return null;
    }

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

    function wifiIconName(network) {
        return networkPresentation.wifiIconName(network);
    }

    function networkKey(network) {
        return root.networkModels.networkKey(network);
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

    property var rNetworks: []

    function setNetworkingEnabled(value) {
        beginOperation("toggle", "networking");
        commands.setNetworkingEnabled(value);
    }

    function scan(callback) {
        root._pendingScanCallback = callback;
        beginOperation("scan", "wifi");
        commands.scan();
    }

    function connectNetwork(id, options) {
        const network = rawNetworkById(id);
        const ssid = network ? network.ssid : id;
        const password = options?.password || "";
        beginOperation("connect", ssid);
        commands.connectToNetwork(ssid, password);
    }

    function disconnectNetwork(id) {
        const network = rawNetworkById(id);
        if (network && network.connected) {
            if (wifiDeviceName) {
                beginOperation("disconnect", network.ssid || id);
                commands.disconnectDevice(wifiDeviceName);
            }
        }
    }

    function refresh() {
        commands.refreshAll();
    }

    function rescan(callback) {
        scan(callback);
    }

    function connectToNetwork(ssid, password) {
        beginOperation("connect", ssid);
        commands.connectToNetwork(ssid, password);
    }

    function disconnectDevice(deviceName) {
        if (deviceName) {
            beginOperation("disconnect", deviceName);
            commands.disconnectDevice(deviceName);
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
            commands.forgetNetwork(uuid);
        }
    }

    function setWifiEnabled(enabled) {
        beginOperation("toggle", "wifi");
        commands.setWifiEnabled(enabled);
    }

    function toggleWifi() {
        setWifiEnabled(!wifiEnabled);
    }

    function executePayload(payload) {
        if (!payload || payload.service !== "network")
            return false;

        switch (payload.op) {
        case "setWifiEnabled":
            root.setWifiEnabled(!!payload.enabled);
            return true;
        case "toggleWifi":
            root.toggleWifi();
            return true;
        case "setNetworkingEnabled":
            root.setNetworkingEnabled(!!payload.enabled);
            return true;
        case "connect":
            root.connectNetwork(payload.id, payload.options || {});
            return true;
        case "disconnect":
            root.disconnectNetwork(payload.id);
            return true;
        case "scan":
            root.scan();
            return true;
        default:
            return false;
        }
    }

    NetworkCommands {
        id: commands

        onNetworkingOutput: function(text) {
            root._updateNetworkingState(text);
        }
        onRadioOutput: function(text) {
            root._updateConnectivity(text);
        }
        onGeneralOutput: function(text) {
            root._updateGeneral(text);
        }
        onNetworksOutput: function(text) {
            root._parseNetworks(text);
            if (root.currentOperationKind === "scan") {
                root.finishOperation(true, "");
                if (root._pendingScanCallback) {
                    root._pendingScanCallback(true);
                    root._pendingScanCallback = null;
                }
            }
        }
        onWiredOutput: function(text) {
            const state = nmcliParser.parseDeviceStatus(text);
            root.hasWiredConnection = state.hasWiredConnection;
            root.wifiDeviceName = state.wifiDeviceName;
            root.wiredDeviceName = state.wiredDeviceName;
            root.wiredAddress = state.wiredAddress;
        }
        onOperationFinished: function(kind, success, message) {
            if (kind === "networking" || kind === "wifi" || kind === "connect" || kind === "disconnect" || kind === "forget") {
                root.finishOperation(success, message);
                if (success)
                    root.refresh();
            } else if (kind === "scan") {
                root.finishOperation(success, message);
                if (root._pendingScanCallback) {
                    root._pendingScanCallback(success);
                    root._pendingScanCallback = null;
                }
            }
        }
    }

    NetworkMonitor {
        id: monitor
        onRefreshRequested: root.refresh()
    }

    Component.onCompleted: {
        monitor.start();
    }
}
