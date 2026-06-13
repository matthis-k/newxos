pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    required property string key
    required property var result
    required property int rank
    required property int zValue
    required property string phase

    property Component sourceComponent: null
    property var controller: null
    property int animationMode: 2
    property int enterDuration: 140
    property int removeDuration: 120
    property int transformDuration: 120
    property int spacing: 0
    property int estimatedRowHeight: 56
    property int iconSize: 32
    property bool showSubtitle: true
    property bool showActionHint: true
    property bool showEvidence: false
    property real reveal: 1
    property real contentOpacity: 1
    property real contentScale: 1
    property bool enterStarted: false
    property bool removing: false
    property bool delayModelRemove: false
    property real fullHeight: Math.max(content.implicitHeight, root.estimatedRowHeight) + root.spacing
    readonly property Item item: content.item

    property Timer removeFallbackTimer: Timer {
        interval: Math.max(1, root.removeDuration + 80)
        repeat: false
        onTriggered: {
            root.ListView.delayRemove = false;
            Qt.callLater(root.settleListView);
        }
    }

    signal activated(int rank)

    width: ListView.view ? ListView.view.width : 0
    height: root.fullHeight * root.reveal
    clip: true
    z: root.zValue
    visible: !!root.sourceComponent || root.removing

    Component.onCompleted: {
        if (root.phase === "entering")
            Qt.callLater(root.startEnterAnimation);
    }

    onPhaseChanged: {
        if (root.phase === "leaving")
            root.startLeaveAnimation(false);
        else if (root.phase === "live" && !root.removing && !enterAnimation.running)
            root.finishVisualState();
    }

    ListView.onAdd: root.startEnterAnimation()

    ListView.onRemove: {
        if (root.phase === "leaving" || root.reveal <= 0.01) {
            root.ListView.delayRemove = false;
            Qt.callLater(root.settleListView);
            return;
        }
        root.startLeaveAnimation(true);
    }

    function startEnterAnimation() {
        if (root.enterStarted || root.phase !== "entering") {
            if (!root.removing && root.phase !== "entering")
                root.finishVisualState();
            return;
        }

        root.enterStarted = true;
        if (root.enterDuration <= 0) {
            root.finishVisualState();
            return;
        }

        root.reveal = 0;
        root.contentOpacity = 0;
        root.contentScale = 0.96;
        Qt.callLater(function() {
            if (!root || root.removing)
                return;
            enterAnimation.restart();
        });
    }

    function finishVisualState() {
        root.removing = false;
        root.delayModelRemove = false;
        root.reveal = 1;
        root.contentOpacity = 1;
        root.contentScale = 1;
    }

    function startLeaveAnimation(delayRemove) {
        root.removing = true;
        root.delayModelRemove = delayRemove;
        enterAnimation.stop();
        if (delayRemove) {
            root.ListView.delayRemove = true;
            removeFallbackTimer.restart();
        } else {
            removeFallbackTimer.stop();
        }

        if (root.removeDuration <= 0) {
            root.finishLeaveAnimation();
            return;
        }

        removeAnimation.restart();
    }

    function finishLeaveAnimation() {
        root.reveal = 0;
        root.contentOpacity = 0;
        root.contentScale = 0.96;
        removeFallbackTimer.stop();
        if (root.delayModelRemove)
            root.ListView.delayRemove = false;
        Qt.callLater(root.settleListView);
    }

    function currentResult() {
        if (root.removing || root.phase === "leaving")
            return root.result;
        if (root.controller && root.controller.results && root.rank >= 0 && root.rank < root.controller.results.length)
            return root.controller.results[root.rank] || root.result;
        return root.result;
    }

    function settleListView() {
        const view = root.ListView.view;
        if (!view)
            return;
        if (typeof view.settleLayout === "function")
            view.settleLayout();
        else if (typeof view.forceLayout === "function")
            view.forceLayout();
    }

    function wireLoadedItem() {
        const loaded = content.item;
        if (!loaded)
            return;

        if ("result" in loaded)
            loaded.result = Qt.binding(function() { return root.currentResult(); });
        if ("resultIndex" in loaded)
            loaded.resultIndex = Qt.binding(function() { return root.rank; });
        if ("selected" in loaded)
            loaded.selected = Qt.binding(function() { return root.controller && root.controller.selectedIndex === root.rank; });
        if ("iconSize" in loaded)
            loaded.iconSize = Qt.binding(function() { return root.iconSize; });
        if ("showSubtitle" in loaded)
            loaded.showSubtitle = Qt.binding(function() { return root.showSubtitle; });
        if ("showActionHint" in loaded)
            loaded.showActionHint = Qt.binding(function() { return root.showActionHint; });
        if ("showEvidence" in loaded)
            loaded.showEvidence = Qt.binding(function() { return root.showEvidence; });
        if ("controller" in loaded)
            loaded.controller = Qt.binding(function() { return root.controller; });
        if (loaded.activated)
            loaded.activated.connect(function() {
                if (!root.removing)
                    root.activated(root.rank);
            });
    }

    ParallelAnimation {
        id: enterAnimation

        NumberAnimation {
            target: root
            property: "reveal"
            to: 1
            duration: root.enterDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "contentOpacity"
            to: 1
            duration: root.transformDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "contentScale"
            to: 1
            duration: root.transformDuration
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: removeAnimation

        NumberAnimation {
            target: root
            property: "reveal"
            to: 0
            duration: root.removeDuration
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "contentOpacity"
            to: 0
            duration: root.removeDuration
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "contentScale"
            to: 0.96
            duration: root.removeDuration
            easing.type: Easing.InCubic
        }

        alwaysRunToEnd: true
        onFinished: root.finishLeaveAnimation()
    }

    Loader {
        id: content

        active: !!root.sourceComponent
        sourceComponent: root.sourceComponent
        width: root.width
        height: implicitHeight
        opacity: root.contentOpacity
        scale: root.contentScale
        transformOrigin: Item.Top
        enabled: !root.removing && root.phase !== "leaving"

        onLoaded: root.wireLoadedItem()
    }
}
