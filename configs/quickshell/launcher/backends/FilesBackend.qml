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
        { pattern: "^files?\\s+(.*)", mode: "exclusive" },
        { pattern: "^file://.*$", mode: "ambient" },
        { pattern: "^[/~].*$", mode: "ambient" }
    ]

    function shouldParticipate(rawQuery, directive, query) {
        const raw = String(rawQuery || "").trim();
        return raw[0] === "/" || raw[0] === "~" || raw.indexOf("file://") === 0 || /^@?files?(\s|$)/.test(raw);
    }

    function rootNode(query, context) {
        const rawQuery = context && context.directive && context.directive.active ? context.directive.raw : (query ? query.raw : "");
        if (!shouldParticipate(rawQuery, context ? context.directive : null, query))
            return null;

        const pathQuery = expandHome(fileQueryText(rawQuery));
        const seenPaths = {};
        const children = [];
        if (pathQuery.length > 0) {
            children.push(nodeForPath(pathQuery, 0));
            seenPaths[pathQuery] = true;
        }

        (root.compositeResults || []).forEach(function(result, index) {
            const metadata = result.metadata || {};
            const path = metadata.path || result.subtitle || result.title || "";
            if (!path || seenPaths[path])
                return;
            seenPaths[path] = true;
            children.push(nodeForPath(path, index + 1, result.title, result.subtitle, result.icon));
        });

        return root.backendRootDto(children, {
            subtitle: root.compositeQuery ? qsTr("Results for %1").arg(root.compositeQuery) : root.helpDescription,
            evaluationProfile: { mode: "generic", strategies: ["exact", "prefix", "compact", "substring", "acronym"], scorePolicy: "backend" }
        });
    }

    function nodeForPath(path, index, title, subtitle, icon) {
        const parts = path.split("/");
        const label = title || parts[parts.length - 1] || path;
        return root.nodeDto({
            id: "file:" + path,
            kind: "file-result",
            label: label,
            subtitle: subtitle || displayPath(path),
            icon: icon || iconForPath(path),
            path: path,
            keywords: [path, label],
            showWhenQueryEmpty: true,
            usageCount: Math.max(0, root.maxResults - index),
            lastUsedDaysAgo: 9999,
            actionList: [
                root.actionDto("open", qsTr("Open", "action: open file"), { path: path, actionId: "open" }),
                root.actionDto("open-folder", qsTr("Open Folder"), { path: path, actionId: "open-folder" }),
                root.actionDto("copy-path", qsTr("Copy Path"), { path: path, actionId: "copy-path" })
            ],
            meta: { path: path }
        });
    }

    function buildCommand(queryText) {
        const text = fileQueryText(queryText);
        if (!text)
            return [];

        const path = text[0] === "/" || text[0] === "~" ? expandHome(text) : root.searchRoot + "/" + text;
        const slash = path.lastIndexOf("/");
        const folder = slash > 0 ? path.slice(0, slash) : "/";
        const name = slash >= 0 ? path.slice(slash + 1) : path;
        return ["fd", "--absolute-path", "--max-results", root.maxResults.toString(), name || ".", folder];
    }

    function fileQueryText(queryText) {
        const text = String(queryText || "").trim();
        if (text.indexOf("file://") === 0)
            return text.slice(7);
        return text.replace(/^@?files?(\s+|$)/, "").trim();
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
        if (path === home)
            return "~";
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

        return {
            id: "file:" + path,
            title: title,
            subtitle: displayPath(path),
            icon: iconForPath(path),
            metadata: { path: path }
        };
    }

    function activate(result, action) {
        const payload = action && action.payload ? action.payload : null;
        const metadata = result ? result.metadata || {} : {};
        if (!result || !(metadata.path || payload && payload.path))
            return;

        const path = metadata.path || payload.path;
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
