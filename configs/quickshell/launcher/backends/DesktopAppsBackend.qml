import QtQml
import Quickshell

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
        { pattern: "^@app\\s+(.*)", mode: "exclusive" },
        { pattern: "^@app$", mode: "exclusive" },
        { pattern: "^@apps\\s+(.*)", mode: "exclusive" },
        { pattern: "^@apps$", mode: "exclusive" },
        { pattern: "^@desktop\\s+(.*)", mode: "exclusive" },
        { pattern: "^@desktop$", mode: "exclusive" },
        { pattern: "^.*$", mode: "ambient" }
    ]

    treePrefixes: ["@app", "@apps", "@desktop"]
    treeRoots: appTree

    readonly property var appTree: buildAppTree()

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
            action: { entryId: entry.id }
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
        if (!entry)
            return;

        const actionId = cmdAction.actionId || (action ? action.id : null);
        if (!actionId || actionId === "open") {
            launchDesktopCommand(entry.command, entry.workingDirectory, entry.runInTerminal);
            return;
        }

        const desktopAction = (entry.actions || []).find(item => item.id === actionId);
        if (desktopAction)
            launchDesktopCommand(desktopAction.command, entry.workingDirectory, entry.runInTerminal);
    }

    function launchDesktopCommand(command, workingDirectory, runInTerminal) {
        if (!command || command.length === 0)
            return;

        if (runInTerminal) {
            Quickshell.execDetached({
                command: ["sh", "-lc", "exec \"${TERMINAL:-kitty}\" -e \"$@\"", "launcher-terminal"].concat(command),
                workingDirectory: workingDirectory || ""
            });
            return;
        }

        Quickshell.execDetached({
            command: command,
            workingDirectory: workingDirectory || ""
        });
    }
}
