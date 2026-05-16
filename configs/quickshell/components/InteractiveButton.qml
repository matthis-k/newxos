import QtQuick

Item {
    id: root

    signal clicked

    property bool flat: false
    property string text: ""
    property url iconSource: ""
    property string iconName: ""

    property Item contentItem: defaultContent

    property int padding: 0
    property int leftPadding: padding
    property int rightPadding: padding
    property int topPadding: padding
    property int bottomPadding: padding

    property Item scaleTarget: root.contentItem
    property Item iconScaleTarget: null
    property Item textScaleTarget: null
    property bool scaleIcon: false
    property bool scaleText: false
    property real hoveredScale: 1.0
    property real unhoveredScale: 0.8
    property real baseScale: 1.0
    property int scaleAnimationDuration: 150
    property int scaleAnimationEasing: Easing.OutCubic
    property int cursorShape: Qt.PointingHandCursor

    readonly property alias hovered: hoverHandler.hovered

    implicitWidth: (contentItem ? contentItem.implicitWidth : 0) + leftPadding + rightPadding
    implicitHeight: (contentItem ? contentItem.implicitHeight : 0) + topPadding + bottomPadding

    function attachItem(item, container) {
        if (!item)
            return;

        item.parent = container;
        if (item.anchors)
            item.anchors.fill = container;
        item.visible = true;
    }

    function applyScale(target, animation, targetScale) {
        if (!target)
            return;

        animation.stop();

        if (scaleAnimationDuration <= 0) {
            target.scale = targetScale;
            return;
        }

        animation.target = target;
        animation.to = targetScale;
        animation.start();
    }

    function updateScale() {
        const hoverFactor = hovered ? hoveredScale : unhoveredScale;
        const targetScale = baseScale * hoverFactor;

        applyScale(scaleTarget, scaleAnimation, targetScale);

        if (scaleIcon && iconScaleTarget)
            applyScale(iconScaleTarget, iconScaleAnimation, targetScale);

        if (scaleText && textScaleTarget)
            applyScale(textScaleTarget, textScaleAnimation, targetScale);
    }

    Item {
        id: contentContainer
        anchors {
            fill: parent
            leftMargin: root.leftPadding
            rightMargin: root.rightPadding
            topMargin: root.topPadding
            bottomMargin: root.bottomPadding
        }
    }

    Item {
        id: defaultContent
        visible: root.contentItem === defaultContent
    }

    NumberAnimation {
        id: scaleAnimation
        property: "scale"
        duration: root.scaleAnimationDuration
        easing.type: root.scaleAnimationEasing
    }

    NumberAnimation {
        id: iconScaleAnimation
        property: "scale"
        duration: root.scaleAnimationDuration
        easing.type: root.scaleAnimationEasing
    }

    NumberAnimation {
        id: textScaleAnimation
        property: "scale"
        duration: root.scaleAnimationDuration
        easing.type: root.scaleAnimationEasing
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: root.cursorShape
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        cursorShape: root.cursorShape
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.clicked()
    }

    onContentItemChanged: attachItem(contentItem, contentContainer)
    onHoveredChanged: updateScale()
    onBaseScaleChanged: updateScale()
    onHoveredScaleChanged: updateScale()
    onUnhoveredScaleChanged: updateScale()
    onScaleTargetChanged: updateScale()
    onIconScaleTargetChanged: updateScale()
    onTextScaleTargetChanged: updateScale()
    onScaleIconChanged: updateScale()
    onScaleTextChanged: updateScale()
    Component.onCompleted: {
        attachItem(contentItem, contentContainer);
        updateScale();
    }
}
