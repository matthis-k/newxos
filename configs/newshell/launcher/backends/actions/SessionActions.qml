import QtQml
import qs.services

QtObject {
    function node(id, aliases, title, subtitle, icon, color, command, risk) { return { id: id, aliases: aliases, title: title, subtitle: subtitle, icon: icon, iconColor: color, action: { service: "desktop", op: "exec", command: command }, dangerous: !!risk, risk: risk || null }; }
    function sessionProfile() { return { mode: "generic+custom", strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"], scorePolicy: "default", profile: { evidence: [["field-match", { filterType: "all" }], "semantic"], boost: ["descendant-boost"], childVisible: ["visible-flag"], tokenFlow: ["consume-namespace-pass-rest"], takeoverRequest: ["child-own-match-parent-no-own-match", "explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"], takeoverAccept: ["accept-dominated-claims"], expand: ["expand-on-own-match-or-trailing-space"], retainParent: [{ name: "retain-parent-when", args: { condition: "own-match" } }], defaultAction: ["default-action-expand"], riskGate: ["risk-gate"] } }; }
    function roots(context) { return [{ id: "session", aliases: ["session", "system"], title: qsTr("Session"), icon: "system-shutdown-symbolic", template: "flat-action-group", behavior: { filterChildren: true }, evaluationProfile: sessionProfile(), children: [
        node("lock", ["lock"], qsTr("Lock"), qsTr("Lock the current session"), "system-lock-screen-symbolic", Config.styling.info, ["loginctl", "lock-session"]),
        node("logout", ["logout", "exit"], qsTr("Log Out"), qsTr("Exit the current Hyprland session"), "system-log-out-symbolic", Config.styling.warning, ["hyprctl", "dispatch", "exit"], { level: "session", activation: "confirm-and-explicit-prefix" }),
        node("shutdown", ["shutdown", "poweroff", "power-off"], qsTr("Shut Down"), qsTr("Power off this machine"), "system-shutdown-symbolic", Config.styling.critical, ["systemctl", "poweroff"], { level: "power", activation: "confirm-and-explicit-prefix" }),
        node("reboot", ["reboot", "restart"], qsTr("Reboot"), qsTr("Restart this machine"), "system-reboot-symbolic", Config.styling.urgent, ["systemctl", "reboot"], { level: "power", activation: "confirm-and-explicit-prefix" }),
        node("hibernate", ["hibernate", "suspend-to-disk"], qsTr("Hibernate"), qsTr("Suspend this machine to disk"), "system-suspend-hibernate-symbolic", Config.styling.secondaryAccent, ["systemctl", "hibernate"], { level: "power", activation: "confirm-and-explicit-prefix" })
    ] }]; }
}
