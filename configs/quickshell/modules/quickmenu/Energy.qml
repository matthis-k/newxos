import QtQuick
import QtQuick.Layouts

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "Energy"
    subtitle: "Battery, brightness, and power profile management"

    DashboardSection {
        Layout.fillWidth: true
        title: "Display"

        LabeledSlider {
            Layout.fillWidth: true
            label: "Brightness"
            iconName: Brightness.iconName
            value: Brightness.percent
            from: 0
            to: 100
            valueText: Brightness.available ? `${Brightness.percent}%` : "Unavailable"
            enabled: Brightness.available
            onValueCommitted: Brightness.setPercent(value)
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Battery and power"

        Battery {
            id: batteryContent
            Layout.fillWidth: true
        }
    }
}
