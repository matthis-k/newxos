import QtQml

QtObject {
    id: root

    property string interactiveNetworkKey: ""
    property bool interactiveShowAdvanced: false
    property bool interactiveShowPasswordInput: false
    property string interactivePasswordText: ""
    property string interactiveErrorText: ""
    property var frozenNetworkOrder: []
    property var networks: []

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
            frozenNetworkOrder = root.networks.map(candidate => networkKey(candidate));
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

    function displayedNetworks(networks) {
        return interactionLocked ? applyFrozenOrder(networks) : networks;
    }
}
