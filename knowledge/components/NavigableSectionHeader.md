---
title: NavigableSectionHeader
type: note
permalink: newxos/components/navigable-section-header
---

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

DashboardPageHeader {
    id: root

    property var screenState: null
    property string targetTab: ""
    property bool isClickable: targetTab !== "" && screenState !== null

    signal clicked

    titleLabel {
        MouseArea {
            anchors.fill: parent
            visible: root.isClickable
            cursorShape: root.isClickable ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: {
                if (root.isClickable) {
                    root.screenState.openDashboard(root.targetTab);
                    root.clicked();
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Config.behaviour.animation.enabled ? Config.behaviour.animation.calc(0.15) : 0
                easing.type: Easing.OutCubic
            }
        }

        color: {
            if (root.isClickable) {
                return Config.styling.primaryAccent;
            }
            return Config.styling.text0;
        }
    }
}
