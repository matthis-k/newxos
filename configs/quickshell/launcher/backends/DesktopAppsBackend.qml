import QtQml
import Quickshell
import "../logic/QueryParsing.js" as QueryParsing
import "../logic/Scoring.js" as Scoring

LauncherBackendBase {
    id: root

    property string category: qsTr("Applications")

    backendId: "desktop"
    name: qsTr("Desktop Applications")
    helpTitle: qsTr("Applications")
    helpDescription: qsTr("Search desktop entries")
    helpIcon: "application-x-executable"
    helpPrefixes: ["@app", "@apps", "@desktop", "app"]
    priority: 80
    maxResults: 6

    Component.onCompleted: console.log("[Launcher][desktop] initialized")

    function canHandle(query) {
        const parsed = QueryParsing.parse(query);
        if (!enabled)
            return false;
        if (parsed.explicit && parsed.targetBackend !== root.backendId)
            return false;
        if (parsed.explicit && parsed.targetBackend === root.backendId)
            return true;
        return parsed.text.length > 0 || parsed.raw.length > 0;
    }

    function searchableText(entry) {
        return [entry.name, entry.genericName, entry.comment, (entry.keywords || []).join(" ")].join(" ");
    }

    function actionLabel(action) {
        return action.name || action.id || qsTr("Run");
    }

    function resultForEntry(entry, queryText, score) {
        const actions = [{ id: "open", label: qsTr("Open", "action: launch app"), icon: "document-open", default: true }];
        for (const action of entry.actions || []) {
            if (!action || !action.id)
                continue;

            actions.push({
                id: action.id,
                label: actionLabel(action),
                icon: action.icon || null,
                default: false
            });
        }

        return {
            id: entry.id,
            source: root.backendId,
            category: root.category,
            title: entry.name || entry.id,
            subtitle: entry.genericName || entry.comment || null,
            icon: entry.icon || "application-x-executable",
            relevance: Math.min(1, Math.max(0.05, score / 50)),
            actions: actions,
            metadata: { desktopEntry: entry.id, query: queryText }
        };
    }

    function search(query, context) {
        const parsed = QueryParsing.parse(query);
        const queryText = parsed.targetBackend === root.backendId ? parsed.text : parsed.raw;
        console.log("[Launcher][desktop] query:", queryText);

        const entries = DesktopEntries.applications.values || [];
        const matches = [];

        for (const entry of entries) {
            if (!entry || entry.noDisplay || !entry.name)
                continue;

            if (!queryText) {
                matches.push(resultForEntry(entry, queryText, 8));
                continue;
            }

            const score = Math.max(
                Scoring.fuzzyScore(queryText, entry.name, entry.genericName),
                Scoring.fuzzyScore(queryText, searchableText(entry), "")
            );

            if (score <= 0)
                continue;

            matches.push(resultForEntry(entry, queryText, score));
        }

        matches.sort((a, b) => b.relevance - a.relevance || a.title.localeCompare(b.title));
        const limited = parsed.targetBackend === root.backendId ? matches : matches.slice(0, root.maxResults);
        console.log("[Launcher][desktop] results:", limited.length);
        return limited;
    }

    function activate(result, action) {
        console.log("[Launcher][desktop] activate:", result ? result.title : "", action ? action.id : "");

        const entryId = result && result.metadata ? result.metadata.desktopEntry : null;
        const entry = entryId ? DesktopEntries.byId(entryId) : null;
        if (!entry) {
            console.warn("[Launcher][desktop] missing desktop entry:", entryId);
            return;
        }

        if (!action || action.id === "open") {
            launchDesktopCommand(entry.command, entry.workingDirectory, entry.runInTerminal);
            return;
        }

        const desktopAction = (entry.actions || []).find(item => item.id === action.id);
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
