import QtQuick
import QtQuick.Layouts

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "Notifications"
    subtitle: NotificationCenter.doNotDisturbEnabled ? "Toasts paused" : "Tracked notification history and actions"
    scrollable: false
    fillHeight: false

    DashboardSection {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Inbox"

        NotificationFeed {
            Layout.fillWidth: true
            Layout.fillHeight: true
            showControls: true
        }
    }
}
