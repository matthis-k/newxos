import QtQml

QtObject {
    function rawDeviceById(adapter, id) {
        if (!adapter) return null;
        for (const device of (adapter.devices.values || [])) {
            if (device.address === id || device.dbusPath === id || device.name === id)
                return device;
        }
        return null;
    }
}
