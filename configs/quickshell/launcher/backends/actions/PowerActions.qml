import QtQml
import qs.services

QtObject {
    function roots(context) { return [{ id: "power-profile", aliases: ["powermode", "power-mode", "profile", "power", "energy"], title: qsTr("Power Mode"), subtitle: PowerService.profileLabel(PowerService.profile), icon: PowerService.profileIconName(PowerService.profile), iconColor: PowerService.profileColor(PowerService.profile), control: { kind: "slider", target: "power-profile", from: 0, to: 2, step: 1, value: PowerService.profileIndex(PowerService.profile) }, behavior: { filterable: true } }]; }
}
