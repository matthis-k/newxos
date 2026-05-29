import QtQml
import QtCore
import Quickshell

ProcessBackendBase {
    id: root

    property string searchRoot: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "")

    category: qsTr("Files")

    backendId: "files"
    name: qsTr("Files")
    helpTitle: qsTr("Files")
    helpDescription: qsTr("Search files from home")
    helpIcon: "folder"
    helpPrefixes: ["@file", "@files"]
    priority: 60
    maxResults: 5
    routes: [
        { pattern: "^@files?\\s+(.*)", mode: "exclusive" },
        { pattern: "^[/~].*$", mode: "ambient" }
    ]

    function buildCommand(queryText) {
        const text = queryText || "";
        if (!text)
            return [];

        const path = text[0] === "/" || text[0] === "~" ? expandHome(text) : text;
        const slash = path.lastIndexOf("/");
        const folder = slash > 0 ? path.slice(0, slash) : "/";
        const name = slash >= 0 ? path.slice(slash + 1) : path;
        return ["fd", "--absolute-path", "--max-results", root.maxResults.toString(), name || ".", folder];
    }

    function parseOutput(text, queryText) {
        const lines = (text || "").trim().split("\n").filter(line => line.length > 0);
        return lines.slice(0, root.maxResults).map((line, index) => resultForPath(line, index));
    }

    function expandHome(path) {
        if (path === "~")
            return StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "");
        if (path.indexOf("~/") === 0)
            return StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + path.slice(1);
        return path;
    }

    function displayPath(path) {
        const home = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "");
        return path.indexOf(home + "/") === 0 ? "~" + path.slice(home.length) : path;
    }

    function iconForPath(path) {
        if (/\.nix$/.test(path))
            return "text-x-nix";
        if (/\.(png|jpe?g|webp|svg)$/.test(path))
            return "image-x-generic";
        if (/\.(mp4|mkv|webm)$/.test(path))
            return "video-x-generic";
        if (/\.(mp3|flac|ogg|wav)$/.test(path))
            return "audio-x-generic";
        return "text-x-generic";
    }

    function resultForPath(path, index) {
        const parts = path.split("/");
        const title = parts[parts.length - 1] || path;

        return root.buildResult({
            id: "file:" + path,
            title: title,
            subtitle: displayPath(path),
            icon: iconForPath(path),
            relevance: Math.max(0.2, 0.9 - index * 0.08),
            actions: [
                { id: "open", label: qsTr("Open", "action: open file"), icon: "document-open", default: true },
                { id: "open-folder", label: qsTr("Open Folder"), icon: "folder-open", default: false },
                { id: "copy-path", label: qsTr("Copy Path"), icon: "edit-copy", default: false }
            ],
            metadata: { path: path }
        });
    }

    function activate(result, action) {
        if (!result || !result.metadata || !result.metadata.path)
            return;

        const path = result.metadata.path;
        if (!action || action.id === "open") {
            Quickshell.execDetached({ command: ["xdg-open", path] });
        } else if (action.id === "open-folder") {
            const folder = path.slice(0, path.lastIndexOf("/")) || "/";
            Quickshell.execDetached({ command: ["xdg-open", folder] });
        } else if (action.id === "copy-path") {
            Quickshell.execDetached({ command: ["wl-copy", path] });
        }
    }
}
