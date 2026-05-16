import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "Networking"
    headerAccessory: Component {
        DashboardToggleSwitch {
            implicitWidth: 58
            implicitHeight: 28
            checked: NetworkService.networkingEnabled
            onToggled: nmcliSetNetworkingProcess.exec({
                command: checked
                    ? ["nmcli", "networking", "on"]
                    : ["nmcli", "networking", "off"]
            })
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

    property string interactiveNetworkKey: ""
    property bool interactiveShowAdvanced: false
    property bool interactiveShowPasswordInput: false
    property string interactivePasswordText: ""
    property string interactiveErrorText: ""
    property var frozenNetworkOrder: []

    readonly property bool interactionLocked: interactiveNetworkKey !== ""

    function networkKey(network) {
        return `${network?.frequency || "unknown"}::${network?.ssid || "hidden"}::${network?.bssid || "unknown"}`;
    }

    function applyFrozenOrder(networks) {
        const order = new Map();
        for (let i = 0; i < frozenNetworkOrder.length; ++i)
            order.set(frozenNetworkOrder[i], i);

        const items = networks.slice();
        items.sort((a, b) => {
            const aIndex = order.has(networkKey(a)) ? order.get(networkKey(a)) : Number.MAX_SAFE_INTEGER;
            const bIndex = order.has(networkKey(b)) ? order.get(networkKey(b)) : Number.MAX_SAFE_INTEGER;

            if (aIndex !== bIndex)
                return aIndex - bIndex;

            return 0;
        });

        return items;
    }

    function lockInteractionFor(network) {
        const key = networkKey(network);
        if (!key)
            return;

        if (!interactionLocked)
            frozenNetworkOrder = NetworkService.networks.map(candidate => networkKey(candidate));

        if (interactiveNetworkKey !== key) {
            interactiveShowAdvanced = false;
            interactiveShowPasswordInput = false;
            interactivePasswordText = "";
            interactiveErrorText = "";
        }

        interactiveNetworkKey = key;
    }

    function unlockInteraction() {
        interactiveNetworkKey = "";
        interactiveShowAdvanced = false;
        interactiveShowPasswordInput = false;
        interactivePasswordText = "";
        interactiveErrorText = "";
        frozenNetworkOrder = [];
    }

    function securityNeedsPsk(security) {
        return security.includes("WPA") || security.includes("WPA2") || security.includes("SAE") || security.includes("wpa-psk") || security.includes("wpa2-psk") || security.includes("sae");
    }

    function isOpenNetwork(network) {
        return network && (network.security === "Open" || network.security === "--" || !network.security);
    }

    function wifiIconName(network) {
        return NetworkService.wifiIconName(network);
    }

    function securityLabel(network) {
        if (!network)
            return "Unknown";

        if (root.isOpenNetwork(network))
            return "Open";

        return network.security;
    }

    function connectivityLabel() {
        const conn = NetworkService.connectivity;
        if (conn === "full")
            return "Connected";
        if (conn === "portal")
            return "Captive portal";
        if (conn === "limited")
            return "Limited";
        if (conn === "none")
            return "No internet";
        return conn;
    }

    function advancedNetworkInfo(network) {
        if (!network)
            return "Network unavailable";

        const lines = [
            `SSID: ${network.ssid || "unknown"}`,
            `BSSID: ${network.bssid || "unknown"}`,
            `Frequency: ${network.frequency || "unknown"} MHz`,
            `Signal: ${Math.round((network.signalStrength || 0) * 100)}%`,
            `Security: ${securityLabel(network)}`,
            `Connected: ${network.connected ? "Yes" : "No"}`
        ];

        return lines.join("\n");
    }


    component NetworkRow: Item {
        id: rowRoot

        required property var network

        readonly property bool hasNetwork: !!network
        readonly property string rowKey: root.networkKey(network)
        readonly property bool expanded: root.interactiveNetworkKey === rowKey
        readonly property bool showAdvanced: expanded && root.interactiveShowAdvanced
        readonly property bool showPasswordInput: expanded && root.interactiveShowPasswordInput
        readonly property string passwordText: expanded ? root.interactivePasswordText : ""
        readonly property string errorText: expanded ? root.interactiveErrorText : ""
        readonly property bool needsPskPrompt: hasNetwork && !network.connected && !root.isOpenNetwork(network) && root.securityNeedsPsk(network.security)

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

        onHasNetworkChanged: {
            if (!hasNetwork && expanded)
                root.unlockInteraction();
        }

        function attemptConnect() {
            if (!hasNetwork) {
                root.unlockInteraction();
                return;
            }

            root.lockInteractionFor(network);
            root.interactiveErrorText = "";

            if (network.connected)
                return;

            if (root.isOpenNetwork(network) || !root.securityNeedsPsk(network.security)) {
                NetworkService.connectToNetwork(network.ssid, "");
                return;
            }

            root.interactiveShowPasswordInput = true;

            if (!root.interactivePasswordText.length) {
                root.interactiveErrorText = "Password required";
                return;
            }

            NetworkService.connectToNetwork(network.ssid, root.interactivePasswordText);
        }

        Connections {
            target: NetworkService

            function onConnectedSsidChanged() {
                if (rowRoot.expanded && rowRoot.hasNetwork && NetworkService.connectedSsid === rowRoot.network.ssid) {
                    root.interactiveErrorText = "";
                    root.interactivePasswordText = "";
                    root.interactiveShowPasswordInput = false;
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: root.itemSpacing

            ActionButton {
                id: header
                Layout.fillWidth: true
                implicitHeight: root.rowHeight
                active: rowRoot.hasNetwork && rowRoot.network.connected
                accentColor: rowRoot.hasNetwork && rowRoot.network.connected ? Config.colors.blue : Config.styling.activeIndicator
                backgroundColor: Config.styling.bg3
                fillOpacity: rowRoot.hasNetwork && rowRoot.network.connected ? 0.28 : Config.behaviour.hoverBgOpacity
                highlightSide: ActiveIndicator.Side.Left
                highlightAnimationMode: ActiveIndicator.AnimationMode.GrowAlong
                highlightThickness: 4
                indicatorOnHover: true
                scaleTarget: null
                flat: true

                onClicked: {
                    if (rowRoot.expanded)
                        root.unlockInteraction();
                    else if (rowRoot.hasNetwork)
                        root.lockInteractionFor(rowRoot.network);
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
                                iconName: root.wifiIconName(rowRoot.network)
                                color: rowRoot.hasNetwork && rowRoot.network.connected ? Config.colors.blue : Config.styling.text0
                                implicitSize: root.itemIconSize
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                id: nameLabel
                                Layout.fillWidth: true
                                text: rowRoot.hasNetwork ? (rowRoot.network.ssid || "Hidden network") : "Unavailable"
                                color: Config.styling.text0
                                font.bold: true
                                font.pixelSize: root.itemTextSize
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: rowRoot.hasNetwork
                                    ? `${root.securityLabel(rowRoot.network)}  |  ${Math.round((rowRoot.network.signalStrength || 0) * 100)}%`
                                    : "Network unavailable"
                                color: Config.styling.text2
                                font.pixelSize: root.itemSubtextSize
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: rowRoot.hasNetwork && rowRoot.network.connected
                                ? "Connected"
                                : rowRoot.hasNetwork && root.securityNeedsPsk(rowRoot.network.security) && !root.isOpenNetwork(rowRoot.network)
                                    ? "Secured"
                                    : "Available"
                            color: rowRoot.hasNetwork && rowRoot.network.connected
                                ? Config.colors.blue
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
                        text: `SSID: ${rowRoot.hasNetwork ? rowRoot.network.ssid : "Unknown"} | BSSID: ${rowRoot.hasNetwork ? rowRoot.network.bssid : "unknown"}`
                        color: Config.styling.text1
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: `Frequency: ${rowRoot.hasNetwork ? rowRoot.network.frequency : "unknown"} MHz | Signal: ${rowRoot.hasNetwork ? Math.round((rowRoot.network.signalStrength || 0) * 100) : 0}%`
                        color: Config.styling.text1
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }

                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        visible: rowRoot.showPasswordInput
                        text: root.interactivePasswordText
                        placeholderText: "Wi-Fi password"
                        echoMode: TextInput.Password
                        color: Config.styling.text0
                        placeholderTextColor: Config.styling.text2
                        selectedTextColor: Config.styling.selectionText
                        selectionColor: Config.styling.selectionBackgroundActive
                        onTextChanged: root.interactivePasswordText = text
                        onAccepted: rowRoot.attemptConnect()

                        background: Rectangle {
                            color: Config.styling.bg3
                            border.width: 1
                            border.color: Config.styling.bg5
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: rowRoot.errorText !== ""
                        text: rowRoot.errorText
                        color: Config.styling.critical
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
                            text: rowRoot.hasNetwork && rowRoot.network.connected ? "Disconnect" : "Connect"
                            onClicked: {
                                if (!rowRoot.hasNetwork) {
                                    root.unlockInteraction();
                                    return;
                                }

                                if (rowRoot.network.connected) {
                                    NetworkService.disconnectWifi();
                                } else {
                                    rowRoot.attemptConnect();
                                }
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
                        text: root.advancedNetworkInfo(rowRoot.network)
                        color: Config.styling.text2
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    readonly property var displayedNetworks: interactionLocked ? applyFrozenOrder(NetworkService.networks) : NetworkService.networks
    readonly property var connectedNetworks: displayedNetworks.filter(n => n.connected)
    readonly property var disconnectedNetworks: displayedNetworks.filter(n => !n.connected)

    onInteractiveNetworkKeyChanged: {
        if (interactiveNetworkKey && !NetworkService.networks.some(network => networkKey(network) === interactiveNetworkKey))
            unlockInteraction();
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Wired connection"

        Rectangle {
            visible: NetworkService.hasWiredConnection
            Layout.fillWidth: true
            color: Config.styling.bg3
            implicitHeight: root.rowHeight + root.horizontalPadding

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.horizontalPadding
                spacing: root.iconTextGap

                Icon {
                    Layout.preferredWidth: root.itemIconSize
                    Layout.preferredHeight: root.itemIconSize
                    iconName: "network-wired-symbolic"
                    color: Config.colors.blue
                    implicitSize: root.itemIconSize
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: NetworkService.wiredDeviceName || "Wired"
                        color: Config.styling.text0
                        font.pixelSize: root.itemTextSize
                        font.bold: true
                    }

                    Text {
                        text: NetworkService.wiredAddress || ""
                        color: Config.styling.text2
                        font.pixelSize: 12
                    }
                }

                SmallButton {
                    text: "Disconnect"
                    onClicked: NetworkService.disconnectWired()
                }
            }
        }

        Text {
            visible: !NetworkService.hasWiredConnection
            text: "No wired connection detected"
            color: Config.styling.text2
            font.pixelSize: 12
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: connectedNetworks.length === 1 ? "Connected network" : "Connected networks"

        Repeater {
            model: connectedNetworks

            delegate: NetworkRow {
                required property var modelData
                Layout.fillWidth: true
                network: modelData
            }
        }

        Text {
            visible: connectedNetworks.length === 0
            text: "No connected Wi-Fi networks"
            color: Config.styling.text2
            font.pixelSize: 12
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Available networks"
        headerAccessory: Component {
            DashboardIconButton {
                enabled: NetworkService.wifiEnabled
                iconName: "view-refresh-symbolic"
                fallbackIconName: "view-refresh-symbolic"
                onClicked: NetworkService.rescan()
            }
        }

        DashboardScrollArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentSpacing: root.itemSpacing

            Repeater {
                model: disconnectedNetworks

                delegate: NetworkRow {
                    required property var modelData
                    Layout.fillWidth: true
                    network: modelData
                }
            }

            Text {
                visible: NetworkService.networks.length === 0
                text: "No Wi-Fi networks found"
                color: Config.styling.text2
                font.pixelSize: 12
            }
        }
    }

    Process {
        id: nmcliSetNetworkingProcess

        function onExited(exitCode) {
            if (exitCode === 0)
                NetworkService.refresh();
        }
    }

    Process {
        id: nmcliSetWifiProcess

        function onExited(exitCode) {
            if (exitCode === 0)
                NetworkService.refresh();
        }
    }
}
