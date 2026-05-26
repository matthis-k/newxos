import QtQuick
import QtQuick.Controls.Basic

Button {
    id: root

    property url iconSource: ""
    property string iconName: ""

    property Item scaleTarget: root.contentItem
    property Item iconScaleTarget: null
    property Item textScaleTarget: null
    property bool scaleIcon: false
    property bool scaleText: false
    property real hoveredScale: 1.0
    property real unhoveredScale: 1.0
    property real baseScale: 1.0
    property int scaleAnimationDuration: 150
    property int scaleAnimationEasing: Easing.OutCubic
    property int cursorShape: Qt.PointingHandCursor

    hoverEnabled: true
    focusPolicy: Qt.TabFocus | Qt.ClickFocus
    background: null
    contentItem: defaultContent

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
        id: defaultContent
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

    onHoveredChanged: updateScale()
    onBaseScaleChanged: updateScale()
    onHoveredScaleChanged: updateScale()
    onUnhoveredScaleChanged: updateScale()
    onScaleTargetChanged: updateScale()
    onIconScaleTargetChanged: updateScale()
    onTextScaleTargetChanged: updateScale()
    onScaleIconChanged: updateScale()
    onScaleTextChanged: updateScale()
    Component.onCompleted: updateScale()
}
