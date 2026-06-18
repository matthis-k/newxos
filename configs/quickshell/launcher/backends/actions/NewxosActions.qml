import QtQml
import Quickshell
import qs.services

QtObject {
    property var groupOptions: ({})

    function isDevMode() { return Quickshell.env("NEWXOS_DEV") === "1" || Quickshell.env("DEVMODE") === "1"; }
    function action(id, title, subtitle, icon, color, payload, extra) { return Object.assign({ id: id, title: title, subtitle: subtitle || "", icon: icon, iconColor: color, action: payload }, extra || {}); }
    function roots(context) { return [{
        id: "newxos", aliases: ["newxos", "nx", "repo"], title: qsTr("Newxos"), icon: "nix-snowflake-symbolic",
        template: "flat-action-group", groupOptions: Object.assign({}, groupOptions, { committedTokenPrefersGroup: true, committedTokenMinParentScore: 0.15, showAllChildrenOnParentMatch: true, flattenAllChildrenOnParentMatch: true, parentMatchMinScore: 0.1 }),
        behavior: { filterable: true, presentation: "discoverable-command-group", displayPolicy: { discoverable: true, breadcrumbMode: "when-parent-dominates" } },
        children: [
            action("switch", qsTr("Switch System"), qsTr("Switch this system to the current flake"), "system-run-symbolic", Config.styling.primaryAccent, { service: "desktop", op: "terminal", pausedTitle: qsTr("newxos switch"), command: "newxos switch" }, { aliases: ["switch", "rebuild"], actionId: "newxos-switch", risk: { level: "privileged", activation: "confirm" } }),
            action("ai", qsTr("AI"), qsTr("Open opencode in the repo"), "utilities-terminal-symbolic", Config.styling.secondaryAccent, { service: "desktop", op: "terminal", command: "newxos ai" }, { aliases: ["ai", "opencode"], actionId: "newxos-ai" }),
            action("git", qsTr("Git"), qsTr("Open lazygit in the repo"), "git-symbolic", Config.styling.info, { service: "desktop", op: "terminal", command: "cd \"$NEWXOS_FLAKE\" && lazygit" }, { aliases: ["git", "log", "lg", "lazygit"], actionId: "newxos-git" }),
            action("reload_shell", qsTr("Reload Shell"), qsTr("Restart the newshell user service"), "view-refresh-symbolic", Config.styling.warning, { service: "desktop", op: "exec", command: ["newxos", "reload_shell"] }, { aliases: ["reload", "shell", "restart", "newshell"], actionId: "newxos-reload-shell" }),
            { id: "devmode", aliases: ["dev", "devmode", "dev-mode"], title: qsTr("Dev Mode"), subtitle: qsTr("Switch between default and dev specialization"), icon: "applications-development-symbolic", iconColor: Config.styling.urgent, template: "switch", switchState: isDevMode(), switchActions: {
                toggle: { id: "toggle", title: qsTr("Toggle"), state: null, payload: { service: "desktop", op: "devmode" } },
                on: { id: "on", title: qsTr("On"), state: true, payload: { service: "desktop", op: "devmode", enabled: true } },
                off: { id: "off", title: qsTr("Off"), state: false, payload: { service: "desktop", op: "devmode", enabled: false } }
            } }
        ]
    }]; }
}
