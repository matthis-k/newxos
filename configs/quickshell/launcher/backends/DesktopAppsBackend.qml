import Quickshell
import "../logic/DebugLogger.js" as DebugLogger

ModelTreeBackendBase {
    id: root

    category: qsTr("Applications")

    backendId: "desktop"
    name: qsTr("Desktop Applications")
    helpTitle: qsTr("Applications")
    helpDescription: qsTr("Search desktop entries")
    helpIcon: "application-x-executable"
    helpPrefixes: ["@app", "@apps", "@desktop"]
    priority: 80
    maxResults: 6
    routes: [
        { prefix: "@app", priority: 80, combine: "exclusive", afterEmpty: "fallthrough" },
        { prefix: "@apps", priority: 80, combine: "exclusive", afterEmpty: "fallthrough" },
        { prefix: "@desktop", priority: 80, combine: "exclusive", afterEmpty: "fallthrough" },
        { priority: 0, combine: "shared", afterEmpty: "stop" }
    ]

    treeRoots: appTree

    readonly property var appTree: buildAppTree()

    function debugLog(category, message, data) {
        if (root.controller && root.controller.debugEnabled)
            DebugLogger.log(category, message, data);
    }

    function skipEntry(entry) {
        if (entry.noDisplay || !entry.name)
            return true;
        const cats = (entry.categories || []).map(c => c.toLowerCase());
        if (cats.indexOf("consoleonly") >= 0 || cats.indexOf("screensaver") >= 0)
            return true;
        return false;
    }

    function buildAppTree() {
        const entries = DesktopEntries.applications.values || [];
        const children = [];
        for (const entry of entries) {
            if (skipEntry(entry))
                continue;
            children.push(entryNode(entry));
        }
        return [{
            id: "apps",
            title: qsTr("Applications"),
            subtitle: qsTr("%1 apps").arg(children.length),
            icon: "application-x-executable",
            result: false,
            behavior: { visualRoot: true },
            children: children
        }];
    }

    function entryNode(entry) {
        const actions = (entry.actions || []).filter(a => a && a.id);
        const base = {
            id: entry.id.replace(/\.desktop$/, "").toLowerCase().replace(/[\s-]/g, "_"),
            title: entry.name,
            subtitle: entry.genericName || entry.comment || null,
            icon: entry.icon || "application-x-executable",
            action: { actionId: "open", entryId: entry.id },
            behavior: { filterable: true, depthPenalty: 0.35 }
        };
        if (actions.length > 0) {
            base.children = actions.map(a => ({
                id: a.id,
                title: a.name || a.id,
                subtitle: entry.name,
                icon: a.icon || entry.icon || "application-x-executable",
                action: { entryId: entry.id, actionId: a.id }
            }));
        }
        return base;
    }

    function activate(result, action) {
        const metadata = result ? result.metadata || {} : {};
        const cmdAction = (action && action.payload) || (metadata.action && metadata.action.payload) || metadata.action || {};
        const entryId = metadata.desktopEntry || cmdAction.entryId;
        const entry = entryId ? DesktopEntries.byId(entryId) : null;
        if (!entry) {
            root.debugLog("desktop-launch", "Desktop entry not found", {
                resultId: result ? result.id : null,
                entryId: entryId || null,
                actionId: cmdAction.actionId || null
            });
            return;
        }

        const actionId = cmdAction.actionId || (action ? action.id : null);
        root.debugLog("desktop-launch", "Activating desktop entry", {
            resultId: result ? result.id : null,
            entryId: entry.id,
            name: entry.name || null,
            actionId: actionId || "open",
            command: entry.command || [],
            workingDirectory: entry.workingDirectory || "",
            runInTerminal: !!entry.runInTerminal
        });
        if (!actionId || actionId === "open" || actionId === "run") {
            launchDesktopCommand(entry.command, entry.workingDirectory, entry.runInTerminal);
            return;
        }

        const desktopAction = (entry.actions || []).find(item => item.id === actionId);
        if (desktopAction) {
            root.debugLog("desktop-launch", "Activating desktop action", {
                entryId: entry.id,
                actionId: actionId,
                command: desktopAction.command || []
            });
            launchDesktopCommand(desktopAction.command, entry.workingDirectory, entry.runInTerminal);
        } else {
            root.debugLog("desktop-launch", "Desktop action not found", {
                entryId: entry.id,
                actionId: actionId,
                availableActions: (entry.actions || []).map(item => item.id || "")
            });
        }
    }

    function launchDesktopCommand(command, workingDirectory, runInTerminal) {
        if (!command || command.length === 0) {
            root.debugLog("desktop-launch", "Empty desktop command", {});
            return;
        }

        const launchCommand = stripDesktopFieldCodes(command);
        if (launchCommand.length === 0) {
            root.debugLog("desktop-launch", "Desktop command only contained field codes", {
                originalCommand: command || []
            });
            return;
        }

        if (runInTerminal) {
            const terminalCommand = ["systemd-run", "--user", "--scope", "--collect", "--same-dir", "--", "setsid", "sh", "-lc", "exec \"${TERMINAL:-kitty}\" -e \"$@\"", "launcher-terminal"].concat(launchCommand);
            root.debugLog("desktop-launch", "Executing terminal desktop command", {
                originalCommand: command,
                launchCommand: launchCommand,
                systemdCommand: terminalCommand,
                workingDirectory: workingDirectory || ""
            });
            Quickshell.execDetached({
                command: terminalCommand,
                workingDirectory: workingDirectory || ""
            });
            return;
        }

        const systemdCommand = ["systemd-run", "--user", "--scope", "--collect", "--same-dir", "--"].concat(launchCommand);
        root.debugLog("desktop-launch", "Executing desktop command", {
            originalCommand: command,
            launchCommand: launchCommand,
            systemdCommand: systemdCommand,
            workingDirectory: workingDirectory || ""
        });
        Quickshell.execDetached({
            command: systemdCommand,
            workingDirectory: workingDirectory || ""
        });
    }

    function stripDesktopFieldCodes(command) {
        return (command || []).filter(arg => !/^%[fFuUdDnNickvm]$/.test(arg || ""));
    }
}
