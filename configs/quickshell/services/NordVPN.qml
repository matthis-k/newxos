pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool connected: false
    property string status: "Disconnected"
    property string server: ""
    property string hostname: ""
    property string ip: ""
    property string country: ""
    property string city: ""
    property string technology: ""
    property string protocol: ""
    property string postQuantumVpn: ""
    property string transfer: ""
    property string uptime: ""

    property var settings: ({})

    function parseStatus(text) {
        const lines = (text || "").trim().split("\n");
        let newAvailable = false;
        let newConnected = false;
        let newStatus = "Disconnected";
        let newServer = "";
        let newHostname = "";
        let newIp = "";
        let newCountry = "";
        let newCity = "";
        let newTechnology = "";
        let newProtocol = "";
        let newPostQuantumVpn = "";
        let newTransfer = "";
        let newUptime = "";

        for (const line of lines) {
            const colonIdx = line.indexOf(":");
            if (colonIdx < 0) continue;

            const key = line.substring(0, colonIdx).trim();
            const value = line.substring(colonIdx + 1).trim();

            switch (key) {
            case "Status":
                newAvailable = true;
                newStatus = value;
                newConnected = value === "Connected";
                break;
            case "Server":
                newServer = value;
                break;
            case "Hostname":
                newHostname = value;
                break;
            case "IP":
                newIp = value;
                break;
            case "Country":
                newCountry = value;
                break;
            case "City":
                newCity = value;
                break;
            case "Current technology":
                newTechnology = value;
                break;
            case "Current protocol":
                newProtocol = value;
                break;
            case "Post-quantum VPN":
                newPostQuantumVpn = value;
                break;
            case "Transfer":
                newTransfer = value;
                break;
            case "Uptime":
                newUptime = value;
                break;
            }
        }

        root.available = newAvailable;
        root.connected = newConnected;
        root.status = newStatus;
        root.server = newServer;
        root.hostname = newHostname;
        root.ip = newIp;
        root.country = newCountry;
        root.city = newCity;
        root.technology = newTechnology;
        root.protocol = newProtocol;
        root.postQuantumVpn = newPostQuantumVpn;
        root.transfer = newTransfer;
        root.uptime = newUptime;
    }

    function parseSettings(text) {
        const lines = (text || "").trim().split("\n");
        const newSettings = {};

        for (const line of lines) {
            const colonIdx = line.indexOf(":");
            if (colonIdx < 0) continue;

            const key = line.substring(0, colonIdx).trim();
            let value = line.substring(colonIdx + 1).trim();

            if (value === "enabled") value = true;
            else if (value === "disabled") value = false;

            newSettings[key] = value;
        }

        root.settings = newSettings;
    }

    function refreshStatus() {
        statusProcess.exec({
            command: ["nordvpn", "status"]
        });
    }

    function refreshSettings() {
        settingsProcess.exec({
            command: ["nordvpn", "settings"]
        });
    }

    function connect() {
        connectProcess.exec({
            command: ["nordvpn", "connect"]
        });
    }

    function disconnect() {
        disconnectProcess.exec({
            command: ["nordvpn", "disconnect"]
        });
    }

    function setSetting(key, value) {
        const strValue = value === true ? "enabled" : value === false ? "disabled" : String(value);
        setProcess.exec({
            command: ["nordvpn", "set", key, strValue]
        });
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseStatus(text)
        }
        function onExited(exitCode) {
            if (exitCode !== 0)
                root.available = false;
        }
    }

    Process {
        id: settingsProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseSettings(text)
        }
    }

    Process {
        id: connectProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                refreshDelay.restart();
        }
    }

    Process {
        id: disconnectProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                refreshDelay.restart();
        }
    }

    Process {
        id: setProcess
        function onExited(exitCode) {
            if (exitCode === 0)
                settingsRefreshDelay.restart();
        }
    }

    Timer {
        id: pollTimer
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refreshStatus();
            root.refreshSettings();
        }
    }

    Timer {
        id: refreshDelay
        interval: 1000
        onTriggered: root.refreshStatus()
    }

    Timer {
        id: settingsRefreshDelay
        interval: 1000
        onTriggered: root.refreshSettings()
    }
}
