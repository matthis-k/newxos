import QtQml

QtObject {
    id: root

    function deviceKey(device) {
        return device?.address || device?.dbusPath || (device ? root.displayFallback(device) : "");
    }

    function collectDevices(adapter, presentation) {
        const items = [];
        if (!adapter)
            return items;

        for (const device of adapter.devices.values || [])
            items.push(device);

        items.sort(function(a, b) {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            if (a.trusted !== b.trusted)
                return a.trusted ? -1 : 1;

            const aFriendly = presentation ? presentation.hasFriendlyName(a) : !!(a?.deviceName || "").trim();
            const bFriendly = presentation ? presentation.hasFriendlyName(b) : !!(b?.deviceName || "").trim();
            if (aFriendly !== bFriendly)
                return aFriendly ? -1 : 1;

            const aName = presentation ? presentation.displayName(a) : root.displayFallback(a);
            const bName = presentation ? presentation.displayName(b) : root.displayFallback(b);
            return aName.localeCompare(bName);
        });

        return items;
    }

    function connectedDevices(devices) {
        return (devices || []).filter(device => !!device && device.connected);
    }

    function otherDevices(devices) {
        return (devices || []).filter(device => !!device && !device.connected);
    }

    function displayFallback(device) {
        return device?.name || device?.deviceName || device?.address || "Bluetooth device";
    }
}
