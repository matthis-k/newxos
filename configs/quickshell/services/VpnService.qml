pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var backend: NordVPN

    readonly property bool available: NordVPN.available
    readonly property bool connected: NordVPN.connected
    readonly property bool connecting: NordVPN.connecting
    readonly property bool busy: NordVPN.connecting

    readonly property string providerName: "NordVPN"

    readonly property string state: {
        if (connecting) return "connecting";
        if (connected) return "connected";
        if (available) return "disconnected";
        return "unavailable";
    }

    readonly property string location: NordVPN.country ? `${NordVPN.city}, ${NordVPN.country}` : ""
    readonly property string country: NordVPN.country
    readonly property string city: NordVPN.city
    readonly property string server: NordVPN.server
    readonly property string hostname: NordVPN.hostname
    readonly property string ip: NordVPN.ip
    readonly property string technology: NordVPN.technology
    readonly property string protocol: NordVPN.protocol

    readonly property var destinations: normalizeDestinations()

    function normalizeDestinations() {
        const result = [];
        const nordDests = NordVPN.destinations || [];
        for (const d of nordDests) {
            result.push({
                id: d.kind === "fastest" ? "fastest" : `${d.kind}-${d.value}`,
                name: d.name,
                value: d.value,
                kind: d.kind,
                label: destinationLabel(d),
                subtext: destinationSubtext(d)
            });
        }
        return result;
    }

    readonly property string iconName: connected ? "network-vpn-symbolic" : "network-vpn-disconnected-symbolic"
    readonly property color iconColor: connected ? Config.styling.good : (connecting ? Config.styling.warning : Config.styling.text1)

    readonly property string label: providerName
    readonly property string statusText: {
        if (connecting) return "Connecting";
        if (connected) return `${country} • ${server}`;
        return "Disconnected";
    }

    readonly property var presentation: {
        return {
            icon: root.iconName,
            color: root.iconColor,
            label: root.label,
            status: root.statusText,
            state: root.state,
            available: root.available,
            connected: root.connected,
            connecting: root.connecting,
            location: root.location,
            server: root.server,
            country: root.country
        };
    }

    function refresh() {
        NordVPN.refreshStatus();
    }

    function connect(destinationId) {
        if (root.connecting)
            return;

        const dests = NordVPN.destinations || [];
        let destination = null;
        if (destinationId && destinationId !== "fastest") {
            const found = dests.find(d => d.value === destinationId || d.name === destinationId);
            if (found)
                destination = found.value;
        }
        NordVPN.connect(destination);
    }

    function disconnect() {
        NordVPN.disconnect();
    }

    function toggle() {
        if (root.connected || root.connecting)
            root.disconnect();
        else
            root.connect(null);
    }

    function destinationLabel(destination) {
        if (!destination)
            return "Unknown";
        if (destination.kind === "fastest")
            return "Fastest server";
        return destination.name;
    }

    function destinationSubtext(destination) {
        if (!destination)
            return "";
        if (destination.kind === "fastest")
            return "Automatic";
        if (destination.kind === "country")
            return "Country";
        return "Group";
    }
}
