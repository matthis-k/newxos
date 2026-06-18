import QtQuick
import QtQml
import Quickshell.Io

QtObject {
    id: root

    signal networksOutput(string text)
    signal radioOutput(string text)
    signal networkingOutput(string text)
    signal generalOutput(string text)
    signal wiredOutput(string text)
    signal operationFinished(string kind, bool success, string message)
    signal scanResult(bool success)

    function refreshAll() {
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

    function scan() {
        rescanProcess.exec({
            command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        });
    }

    function setNetworkingEnabled(value) {
        const cmd = value ? "on" : "off";
        nmcliNetworkingProcess.exec({
            command: ["nmcli", "networking", cmd]
        });
    }

    function setWifiEnabled(enabled) {
        const cmd = enabled ? "on" : "off";
        wifiToggleProcess.exec({
            command: ["nmcli", "radio", "wifi", cmd]
        });
    }

    function connectToNetwork(ssid, password) {
        const args = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password)
            args.push("password", password);
        connectProcess.exec({
            command: args
        });
    }

    function disconnectDevice(deviceName) {
        if (!deviceName) return;
        disconnectProcess.exec({
            command: ["nmcli", "dev", "disconnect", deviceName]
        });
    }

    function forgetNetwork(uuid) {
        if (!uuid) return;
        forgetProcess.exec({
            command: ["nmcli", "con", "delete", "uuid", uuid]
        });
    }

    function _checkWiredConnection() {
        wiredCheckProcess.exec({
            command: ["nmcli", "-g", "DEVICE,TYPE,STATE,IP4.ADDRESS", "device", "status"]
        });
    }

    function _onOperationExited(exitCode, kind, failMsg) {
        root.operationFinished(kind, exitCode === 0, exitCode === 0 ? "" : `${failMsg} (${exitCode})`);
    }

    Process {
        id: networkingStateProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.networkingOutput(text)
        }
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.radioOutput(text)
        }
    }

    Process {
        id: generalProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.generalOutput(text)
        }
    }

    Process {
        id: rescanProcess
        function onExited(exitCode) {
            if (exitCode === 0) {
                getNetworksProcess.exec({
                    command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "wifi"]
                });
            } else {
                root.scanResult(false);
                root.operationFinished("scan", false, `scan failed (${exitCode})`);
            }
        }
    }

    Process {
        id: getNetworksProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.networksOutput(text);
                root.scanResult(true);
            }
        }
    }

    Process {
        id: wiredCheckProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.wiredOutput(text)
        }
    }

    Process {
        id: nmcliNetworkingProcess
        function onExited(exitCode) {
            root._onOperationExited(exitCode, "networking", "networking toggle failed");
        }
    }

    Process {
        id: connectProcess
        function onExited(exitCode) {
            root._onOperationExited(exitCode, "connect", "connect failed");
        }
    }

    Process {
        id: disconnectProcess
        function onExited(exitCode) {
            root._onOperationExited(exitCode, "disconnect", "disconnect failed");
        }
    }

    Process {
        id: forgetProcess
        function onExited(exitCode) {
            root._onOperationExited(exitCode, "forget", "forget failed");
        }
    }

    Process {
        id: wifiToggleProcess
        function onExited(exitCode) {
            root._onOperationExited(exitCode, "wifi", "wifi toggle failed");
        }
    }
}
