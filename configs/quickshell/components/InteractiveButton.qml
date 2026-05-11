import QtQuick

Item {
    id: control

    signal clicked

    property bool flat: false
    property string text: ""
    property var iconSource: undefined
    property string iconName: ""

    property Item contentItem: defaultContent

    property int padding: 0
    property int leftPadding: padding
    property int rightPadding: padding
    property int topPadding: padding
    property int bottomPadding: padding

    property Item scaleTarget: control.contentItem
    property Item iconScaleTarget: null
    property Item textScaleTarget: null
    property bool scaleIcon: false
    property bool scaleText: false
    property real hoveredScale: 1.0
    property real unhoveredScale: 0.8
    property real baseScale: 1.0
    property int scaleAnimationDuration: 150
    property var scaleAnimationEasing: Easing.OutCubic
    property int cursorShape: Qt.PointingHandCursor

    readonly property alias hovered: hoverHandler.hovered

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

    onContentItemChanged: attachItem(contentItem, contentContainer)

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.leftMargin: control.leftPadding
        anchors.rightMargin: control.rightPadding
        anchors.topMargin: control.topPadding
        anchors.bottomMargin: control.bottomPadding
    }

    Item {
        id: defaultContent
        visible: control.contentItem === defaultContent
    }

    NumberAnimation {
        id: scaleAnimation
        property: "scale"
        duration: control.scaleAnimationDuration
        easing.type: control.scaleAnimationEasing
    }

    NumberAnimation {
        id: iconScaleAnimation
        property: "scale"
        duration: control.scaleAnimationDuration
        easing.type: control.scaleAnimationEasing
    }

    NumberAnimation {
        id: textScaleAnimation
        property: "scale"
        duration: control.scaleAnimationDuration
        easing.type: control.scaleAnimationEasing
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: control.cursorShape
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        cursorShape: control.cursorShape
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: control.clicked()
    }

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
