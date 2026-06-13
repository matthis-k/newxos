import QtQuick
import qs.services

ParallelAnimation {
    id: root

    property string opacityProperty: "opacity"
    property string sizeProperty: "height"
    property real opacityFrom: 0
    property real opacityTo: 1
    property real sizeFrom: 0
    property int sizeKind: MotionAnimation.Kind.Layout

    FadeInAnimation {
        properties: root.opacityProperty
        from: root.opacityFrom
        to: root.opacityTo
        motionDuration: Config.motion.short
    }

    MotionAnimation {
        properties: root.sizeProperty
        from: root.sizeFrom
        kind: root.sizeKind
    }
}
