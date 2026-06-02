import QtQml
import Quickshell
import Quickshell.Io

StreamingBackendBase {
    id: root

    property var pendingQuery: ""
    property var pendingCallback: null

    function cancelSearch(query, generation) {
        root.pendingCallback = null;
        root.pendingQuery = "";
        searchProcess.running = false;
        root.searchCancelled(query || root.activeQuery, generation || root.activeGeneration);
        root.activeQuery = "";
        root.activeGeneration = 0;
    }

    function buildCommand(queryText) {
        return [];
    }

    function parseOutput(text, queryText) {
        return [];
    }

    function applySearchOutput(text) {
        const results = root.parseOutput(text, root.pendingQuery);
        const callback = root.pendingCallback;
        const query = root.pendingQuery;
        root.pendingCallback = null;
        root.pendingQuery = "";
        root.finishSearch(query, root.activeGeneration);
        if (callback)
            callback({ op: "reset", items: results });
    }

    function resultsAsync(query, callback) {
        const text = root.queryText(query);
        if (!text) {
            if (callback)
                callback([]);
            return;
        }

        if (root.pendingQuery || root.pendingCallback)
            root.cancelSearch(root.pendingQuery, root.activeGeneration);
        root.beginSearch(text, 0);
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
