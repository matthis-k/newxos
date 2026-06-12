import QtQuick
import qs.services

NumberAnimation {
    id: root

    enum Kind {
        Micro,
        Short,
        Medium,
        Long,
        Enter,
        Exit,
        Layout,
        Neutral
    }

    property int kind: PropertyAnimation.Kind.Short
    property int motionDuration: {
        switch (kind) {
        case PropertyAnimation.Kind.Micro:
            return Config.motion.micro;
        case PropertyAnimation.Kind.Medium:
        case PropertyAnimation.Kind.Layout:
            return Config.motion.medium;
        case PropertyAnimation.Kind.Long:
            return Config.motion.long;
        default:
            return Config.motion.short;
        }
    }
    property int motionEasingType: {
        switch (kind) {
        case PropertyAnimation.Kind.Exit:
            return Easing.InCubic;
        case PropertyAnimation.Kind.Layout:
            return Easing.InOutCubic;
        case PropertyAnimation.Kind.Neutral:
            return Easing.InOutQuad;
        default:
            return Easing.OutCubic;
        }
    }

    duration: motionDuration
    easing.type: motionEasingType
}
