.pragma library

const prefixes = {
    "=": { backend: "calculator", value: "=", explicit: true },
    "?": { backend: "backends", value: "?", explicit: true },
    "g": { backend: "web", engine: "g", value: "g", explicit: true },
    "ddg": { backend: "web", engine: "ddg", value: "ddg", explicit: true },
    "gh": { backend: "web", engine: "gh", value: "gh", explicit: true },
    "yt": { backend: "web", engine: "yt", value: "yt", explicit: true },
    "app": { backend: "desktop", value: "app", explicit: true },
    "file": { backend: "files", value: "file", explicit: true },
    "@app": { backend: "desktop", value: "@app", explicit: true },
    "@apps": { backend: "desktop", value: "@apps", explicit: true },
    "@desktop": { backend: "desktop", value: "@desktop", explicit: true },
    "@calc": { backend: "calculator", value: "@calc", explicit: true },
    "@calculator": { backend: "calculator", value: "@calculator", explicit: true },
    "@web": { backend: "web", engine: "default", value: "@web", explicit: true },
    "@file": { backend: "files", value: "@file", explicit: true },
    "@files": { backend: "files", value: "@files", explicit: true }
};

function parse(query) {
    const raw = (query || "").trim();
    if (!raw)
        return { raw: "", text: "", prefix: null, targetBackend: null, explicit: false };

    const parts = raw.split(/\s+/);
    const token = parts[0].toLowerCase();
    const prefix = prefixes[token];

    if (!prefix)
        return { raw: raw, text: raw, prefix: null, targetBackend: null, explicit: false };

    return {
        raw: raw,
        text: raw.slice(parts[0].length).trim(),
        prefix: prefix.value,
        engine: prefix.engine || null,
        targetBackend: prefix.backend,
        explicit: true
    };
}

function isExplicitFor(parsed, backendId) {
    return !!parsed && parsed.explicit && parsed.targetBackend === backendId;
}
