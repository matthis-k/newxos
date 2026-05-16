import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell.Bluetooth

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "Bluetooth"
    headerAccessory: Component {
        DashboardToggleSwitch {
            implicitWidth: 58
            implicitHeight: 28
            enabled: !!root.adapter
            checked: !!root.adapter && root.adapter.enabled
            onToggled: {
                if (root.adapter)
                    root.adapter.enabled = checked;
            }
        }
    }

    readonly property int contentWidth: width > 0 ? width : 320
    readonly property int itemSpacing: 3
    readonly property int rowHeight: 36
    readonly property int iconSlotWidth: 28
    readonly property int iconSize: 20
    readonly property int itemIconSize: 22
    readonly property int itemTextSize: 16
    readonly property int itemSubtextSize: 12
    readonly property int iconTextGap: 10
    readonly property int horizontalPadding: 8
    readonly property int verticalPadding: 4

    property string interactiveDeviceKey: ""
    property bool interactiveShowAdvanced: false
    property var frozenDeviceOrder: [ ]

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var allDevices: collectDevices()
    readonly property int connectedCount: adapter ? (adapter.devices.values || []).filter(device => device.connected).length : 0
    readonly property bool interactionLocked: interactiveDeviceKey !== ""
    readonly property var displayedDevices: interactionLocked ? applyFrozenOrder(allDevices) : allDevices
    readonly property var connectedDevices: displayedDevices.filter(device => !!device && device.connected)
    readonly property var otherDevices: displayedDevices.filter(device => !!device && !device.connected)
    readonly property bool interactiveDevicePresent: !interactionLocked || displayedDevices.some(device => deviceKey(device) === interactiveDeviceKey)

    function collectDevices() {
        const items = [];
        const currentAdapter = adapter;

        if (!currentAdapter)
            return items;

        for (const device of currentAdapter.devices.values || [])
            items.push(device);

        items.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;

            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;

            if (a.trusted !== b.trusted)
                return a.trusted ? -1 : 1;

            if (hasFriendlyName(a) !== hasFriendlyName(b))
                return hasFriendlyName(a) ? -1 : 1;

            return displayName(a).localeCompare(displayName(b));
        });

        return items;
    }

    function deviceKey(device) {
        return device?.address || device?.dbusPath || displayName(device);
    }

    function applyFrozenOrder(devices) {
        const order = new Map();
        for (let i = 0; i < frozenDeviceOrder.length; ++i)
            order.set(frozenDeviceOrder[i], i);

        const items = devices.slice();
        items.sort((a, b) => {
            const aIndex = order.has(deviceKey(a)) ? order.get(deviceKey(a)) : Number.MAX_SAFE_INTEGER;
            const bIndex = order.has(deviceKey(b)) ? order.get(deviceKey(b)) : Number.MAX_SAFE_INTEGER;

            if (aIndex !== bIndex)
                return aIndex - bIndex;

            return 0;
        });

        return items;
    }

    function lockInteractionFor(device) {
        const key = deviceKey(device);
        if (!key)
            return;

        if (!interactionLocked)
            frozenDeviceOrder = allDevices.map(candidate => deviceKey(candidate));

        if (interactiveDeviceKey !== key)
            interactiveShowAdvanced = false;

        interactiveDeviceKey = key;
    }

    function unlockInteraction() {
        interactiveDeviceKey = "";
        interactiveShowAdvanced = false;
        frozenDeviceOrder = [ ];
    }

    function displayName(device) {
        return device?.name || device?.deviceName || device?.address || "Bluetooth device";
    }

    function hasFriendlyName(device) {
        const name = device?.deviceName || "";
        return !!name.trim();
    }

    function batteryLabel(device) {
        return device?.batteryAvailable ? `${Math.round((device.battery || 0) * 100)}%` : "No battery";
    }

    function deviceTypeLabel(device) {
        const icon = (device?.icon || "").replace(/-symbolic$/, "");
        if (icon.includes("headphones"))
            return "Headphones";
        if (icon.includes("headset"))
            return "Headset";
        if (icon.includes("speaker"))
            return "Speaker";
        if (icon.includes("audio"))
            return "Audio device";
        if (icon.includes("mouse"))
            return "Mouse";
        if (icon.includes("keyboard"))
            return "Keyboard";
        if (icon.includes("gamepad") || icon.includes("joystick"))
            return "Controller";
        if (icon.includes("phone"))
            return "Phone";
        if (icon.includes("computer") || icon.includes("laptop"))
            return "Computer";
        if (icon.includes("tablet"))
            return "Tablet";
        if (icon.includes("watch"))
            return "Watch";
        return "Bluetooth device";
    }

    function adapterStatusLabel() {
        if (!adapter)
            return "No adapter";
        return BluetoothAdapterState.toString(adapter.state).replace(/([a-z])([A-Z])/g, "$1 $2");
    }

    function adapterIconName() {
        if (!adapter)
            return "bluetooth-disabled-symbolic";
        if (adapter.state === BluetoothAdapterState.Blocked)
            return "bluetooth-disabled-symbolic";
        if (!adapter.enabled || adapter.state === BluetoothAdapterState.Disabled)
            return "bluetooth-disabled-symbolic";
        if (connectedCount > 0)
            return "bluetooth-connected-symbolic";
        if (adapter.discovering)
            return "bluetooth-searching-symbolic";
        return "bluetooth-symbolic";
    }

    function deviceStatusLabel(device) {
        if (!device)
            return "Unavailable";
        return BluetoothDeviceState.toString(device.state);
    }

    function advancedDeviceInfo(device) {
        if (!device)
            return "Device unavailable";

        return [
            `Type: ${deviceTypeLabel(device)}`,
            `Address: ${device.address || "unknown"}`,
            `Adapter: ${device.adapter ? `${device.adapter.name} (${device.adapter.adapterId})` : "unknown"}`,
            `State: ${deviceStatusLabel(device)}`,
            `Battery: ${batteryLabel(device)}`,
            `Paired: ${device.paired ? "Yes" : "No"}`,
            `Bonded: ${device.bonded ? "Yes" : "No"}`,
            `Trusted: ${device.trusted ? "Yes" : "No"}`,
            `Wake allowed: ${device.wakeAllowed ? "Yes" : "No"}`,
            `Blocked: ${device.blocked ? "Yes" : "No"}`
        ].join("\n");
    }

    onInteractiveDevicePresentChanged: {
        if (!interactiveDevicePresent)
            unlockInteraction();
    }


    component DeviceRow: Item {
        id: rowRoot

        required property var device

        readonly property bool hasDevice: !!device
        readonly property string rowKey: root.deviceKey(device)
        readonly property bool expanded: root.interactiveDeviceKey === rowKey
        readonly property bool showAdvanced: expanded && root.interactiveShowAdvanced
        readonly property bool isConnecting: hasDevice && device.state === BluetoothDeviceState.Connecting
        readonly property bool isDisconnecting: hasDevice && device.state === BluetoothDeviceState.Disconnecting

        implicitWidth: root.contentWidth
        implicitHeight: header.implicitHeight + (expanded ? details.implicitHeight + root.itemSpacing : 0)
        height: implicitHeight

        Behavior on height {
            NumberAnimation {
                duration: Config.behaviour.animation.enabled
                    ? Config.behaviour.animation.calc(0.18)
                    : 0
                easing.type: Easing.OutCubic
            }
        }

        onHasDeviceChanged: {
            if (!hasDevice && expanded)
                root.unlockInteraction();
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: root.itemSpacing

            ActionButton {
                id: header
                Layout.fillWidth: true
                implicitHeight: root.rowHeight
                active: rowRoot.hasDevice && rowRoot.device.connected
                accentColor: rowRoot.hasDevice && rowRoot.device.connected ? Config.colors.blue : Config.styling.bluetooth
                backgroundColor: Config.styling.bg3
                fillOpacity: rowRoot.hasDevice && rowRoot.device.connected ? 0.28 : Config.behaviour.hoverBgOpacity
                highlightSide: ActiveIndicator.Side.Left
                highlightAnimationMode: ActiveIndicator.AnimationMode.GrowAlong
                highlightThickness: 4
                indicatorOnHover: true
                scaleTarget: null
                flat: true

                onClicked: {
                    if (rowRoot.expanded)
                        root.unlockInteraction();
                    else if (rowRoot.hasDevice)
                        root.lockInteractionFor(rowRoot.device);
                }

                contentItem: Item {
                    implicitWidth: root.contentWidth
                    implicitHeight: Math.max(root.rowHeight, rowContent.implicitHeight + root.verticalPadding * 2)

                    RowLayout {
                        id: rowContent
                        anchors {
                            fill: parent
                            leftMargin: root.horizontalPadding
                            rightMargin: root.horizontalPadding
                            topMargin: root.verticalPadding
                            bottomMargin: root.verticalPadding
                        }
                        spacing: root.iconTextGap

                        Item {
                            Layout.preferredWidth: root.iconSlotWidth
                            Layout.minimumWidth: root.iconSlotWidth
                            Layout.maximumWidth: root.iconSlotWidth
                            Layout.preferredHeight: root.itemIconSize
                            Layout.alignment: Qt.AlignVCenter

                            Icon {
                                anchors.fill: parent
                                iconName: rowRoot.hasDevice ? rowRoot.device.icon : "bluetooth-symbolic"
                                fallbackIconName: "bluetooth-symbolic"
                                color: rowRoot.hasDevice && rowRoot.device.connected ? Config.colors.blue : Config.styling.text0
                                implicitSize: root.itemIconSize
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: rowRoot.hasDevice ? root.displayName(rowRoot.device) : "Unavailable"
                                color: Config.styling.text0
                                font.bold: true
                                font.pixelSize: root.itemTextSize
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: rowRoot.hasDevice
                                    ? `${root.deviceTypeLabel(rowRoot.device)} | ${root.batteryLabel(rowRoot.device)}${rowRoot.device.paired ? " | Paired" : ""}`
                                    : "Device unavailable"
                                color: Config.styling.text2
                                font.pixelSize: root.itemSubtextSize
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: rowRoot.hasDevice
                                ? rowRoot.device.connected
                                    ? "Connected"
                                    : rowRoot.isConnecting
                                        ? "Connecting"
                                        : rowRoot.isDisconnecting
                                            ? "Disconnecting"
                                            : rowRoot.device.pairing
                                                ? "Pairing"
                                                : rowRoot.device.paired
                                                    ? "Paired"
                                                    : "Available"
                                : "Unavailable"
                            color: rowRoot.hasDevice && rowRoot.device.connected
                                ? Config.colors.blue
                                : rowRoot.isConnecting || rowRoot.isDisconnecting || (rowRoot.hasDevice && rowRoot.device.pairing)
                                    ? Config.colors.yellow
                                    : Config.styling.text1
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }

            Rectangle {
                id: details
                Layout.fillWidth: true
                visible: rowRoot.expanded || opacity > 0
                color: Config.styling.bg1
                clip: true
                opacity: rowRoot.expanded ? 1 : 0
                implicitHeight: visible ? detailsColumn.implicitHeight + root.horizontalPadding * 2 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.behaviour.animation.enabled
                            ? Config.behaviour.animation.calc(0.14)
                            : 0
                        easing.type: Easing.OutCubic
                    }
                }

                ColumnLayout {
                    id: detailsColumn
                    anchors.fill: parent
                    anchors.margins: root.horizontalPadding
                    spacing: Config.spacing.xxs

                    Text {
                        Layout.fillWidth: true
                        text: rowRoot.hasDevice
                            ? `State: ${root.deviceStatusLabel(rowRoot.device)} | Adapter: ${rowRoot.device.adapter ? rowRoot.device.adapter.adapterId : "unknown"}`
                            : "Device unavailable"
                        color: Config.styling.text1
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        implicitHeight: 28
                        spacing: root.itemSpacing

                        SmallButton {
                            Layout.fillWidth: true
                            text: rowRoot.hasDevice && rowRoot.device.connected
                                ? "Disconnect"
                                : rowRoot.hasDevice && !rowRoot.device.paired
                                    ? (rowRoot.device.pairing ? "Cancel Pair" : "Pair")
                                    : "Connect"
                            onClicked: {
                                if (!rowRoot.hasDevice) {
                                    root.unlockInteraction();
                                    return;
                                }

                                if (rowRoot.device.connected)
                                    rowRoot.device.disconnect();
                                else if (!rowRoot.device.paired)
                                    rowRoot.device.pairing ? rowRoot.device.cancelPair() : rowRoot.device.pair();
                                else
                                    rowRoot.device.connect();
                            }
                        }

                        SmallButton {
                            visible: rowRoot.hasDevice && (rowRoot.device.paired || rowRoot.device.bonded || rowRoot.device.trusted)
                            text: rowRoot.hasDevice && rowRoot.device.trusted ? "Untrust" : "Trust"
                            onClicked: {
                                if (rowRoot.hasDevice)
                                    rowRoot.device.trusted = !rowRoot.device.trusted;
                            }
                        }

                        SmallButton {
                            visible: rowRoot.hasDevice && (rowRoot.device.paired || rowRoot.device.bonded)
                            text: "Forget"
                            onClicked: {
                                if (!rowRoot.hasDevice) {
                                    root.unlockInteraction();
                                    return;
                                }

                                rowRoot.device.forget();
                                root.unlockInteraction();
                            }
                        }

                        SmallButton {
                            text: rowRoot.showAdvanced ? "Hide Advanced" : "Show Advanced"
                            onClicked: root.interactiveShowAdvanced = !root.interactiveShowAdvanced
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: rowRoot.showAdvanced
                        text: root.advancedDeviceInfo(rowRoot.device)
                        color: Config.styling.text2
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Connected devices"

        Repeater {
            model: root.connectedDevices

            delegate: DeviceRow {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
            }
        }

        Text {
            visible: root.connectedDevices.length === 0
            text: "No connected Bluetooth devices"
            color: Config.styling.text2
            font.pixelSize: 12
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Other devices"
        headerAccessory: Component {
            DashboardIconButton {
                enabled: !!root.adapter && root.adapter.enabled
                iconName: "view-refresh-symbolic"
                fallbackIconName: "view-refresh-symbolic"
                onClicked: {
                    if (root.adapter)
                        root.adapter.discovering = !root.adapter.discovering;
                }
            }
        }

        DashboardScrollArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentSpacing: root.itemSpacing

            Repeater {
                model: root.otherDevices

                delegate: DeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }

            Text {
                visible: root.displayedDevices.length === 0
                text: root.adapter && root.adapter.enabled ? "No Bluetooth devices found" : "Bluetooth is off"
                color: Config.styling.text2
                font.pixelSize: 12
            }
        }
    }
}
