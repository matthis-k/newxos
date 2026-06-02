.pragma library

function routeMatches(query, route) {
    const raw = String(query || "").trim();
    if (route.pattern) {
        try {
            const re = new RegExp(route.pattern);
            return re.test(raw);
        } catch (e) {
            return false;
        }
    }
    for (const prefix of route.prefixes || []) {
        if (prefix === "" || raw.startsWith(prefix))
            return true;
    }
    return false;
}

function extractText(query, route) {
    const raw = String(query || "").trim();
    if (route.pattern) {
        try {
            const re = new RegExp(route.pattern);
            const m = re.exec(raw);
            if (m && m[1] !== undefined)
                return m[1].trim();
            return raw;
        } catch (e) {
            return raw;
        }
    }
    const prefixes = (route.prefixes || []).slice().sort((a, b) => b.length - a.length);
    for (const prefix of prefixes) {
        if (prefix !== "" && raw.startsWith(prefix))
            return raw.slice(prefix.length).replace(/^\s+/, "");
    }
    return raw;
}


