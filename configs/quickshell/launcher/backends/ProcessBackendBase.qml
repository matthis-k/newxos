import QtQml
import Quickshell
import Quickshell.Io

LauncherBackendBase {
    id: root

    property var pendingQuery: ""
    property var pendingCallback: null

    function buildCommand(queryText) {
        return [];
    }

    function parseOutput(text, queryText) {
        return [];
    }

    function results(query) {
        const text = root.queryText(query);
        if (!text)
            return [];

        root.pendingQuery = text;
        root.pendingCallback = null;

        const command = root.buildCommand(text);
        if (!command || command.length === 0)
            return [];

        searchProcess.exec({ command: command });
        return [];
    }

    function applySearchOutput(text) {
        const results = root.parseOutput(text, root.pendingQuery);
        const callback = root.pendingCallback;
        root.pendingCallback = null;
        root.pendingQuery = "";
        if (callback && results.length > 0)
            callback(results);
    }

    function resultsAsync(query, callback) {
        const text = root.queryText(query);
        if (!text) {
            if (callback)
                callback([]);
            return;
        }

        root.pendingQuery = text;
        root.pendingCallback = callback;

        const command = root.buildCommand(text);
        if (!command || command.length === 0) {
            if (callback)
                callback([]);
            root.pendingCallback = null;
            root.pendingQuery = "";
            return;
        }

        searchProcess.exec({ command: command });
    }

    property Process searchProcess: Process {
        id: searchProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applySearchOutput(text)
        }
        function onExited(exitCode) {
            if (exitCode !== 0)
                root.applySearchOutput("");
        }
    }
}
