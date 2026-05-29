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

function matchRoute(query, route) {
    if (!routeMatches(query, route))
        return null;
    return {
        text: extractText(query, route),
        route: route
    };
}

function matches(query, backends) {
    const all = [];
    console.warn("ROUTER matches query:", query, "backends:", (backends || []).map(b => b ? b.backendId : "null"));
    for (const backend of backends || []) {
        if (!backend || !backend.enabled)
            continue;

        const routes = backend.routes || [];
        console.warn("ROUTER checking backend:", backend.backendId, "enabled:", backend.enabled, "routes:", routes.length);
        for (const route of routes) {
            const matched = matchRoute(query, route);
            if (!matched)
                continue;

            all.push({
                backend: backend,
                route: matched.route,
                routedText: matched.text
            });
        }

        if (routes.length === 0 && backend.isEnabled && backend.isEnabled(query)) {
            all.push({
                backend: backend,
                route: { pattern: "^.*$", mode: "ambient" },
                routedText: query || ""
            });
        }
    }

    const exclusive = all.filter(match => match.route.mode === "exclusive");
    if (exclusive.length > 0)
        return exclusive;

    const participate = all.filter(match => match.route.mode === "participate");
    if (participate.length > 0)
        return participate;

    return all.filter(match => match.route.mode === "ambient");
}

function fallbacks(query, backends) {
    const result = [];
    for (const backend of backends || []) {
        if (!backend || !backend.enabled)
            continue;
        for (const route of backend.routes || []) {
            if (route.mode !== "fallback")
                continue;
            const matched = matchRoute(query, route);
            if (!matched)
                continue;
            result.push({
                backend: backend,
                route: matched.route,
                routedText: matched.text
            });
        }
    }
    return result;
}
