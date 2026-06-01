.pragma library


function clamp(n, min, max) {
    return Math.max(min === undefined ? 0 : min, Math.min(max === undefined ? 1 : max, n));
}

function normalizeText(text) {
    var value = String(text === undefined || text === null ? "" : text);
    if (value.normalize)
        value = value.normalize("NFKD").replace(/[\u0300-\u036f]/g, "");
    return value.toLowerCase();
}

function splitWordsWithRanges(text) {
    var source = String(text === undefined || text === null ? "" : text);
    var words = [];
    var re = /[A-Za-z0-9]+/g;
    var match;
    while ((match = re.exec(source)) !== null) {
        words.push({
            raw: match[0],
            norm: normalizeText(match[0]),
            start: match.index,
            end: match.index + match[0].length
        });
    }
    return words;
}

function compactWithMap(text) {
    var source = String(text === undefined || text === null ? "" : text);
    var chars = [];
    var map = [];
    for (var i = 0; i < source.length; i += 1) {
        var c = normalizeText(source[i]);
        if (/^[a-z0-9]$/.test(c)) {
            chars.push(c);
            map.push(i);
        }
    }
    return { compact: chars.join(""), map: map };
}

function getAcronymRanges(text) {
    return splitWordsWithRanges(text).map(function(w) {
        return { char: w.norm[0] || "", start: w.start, end: Math.min(w.start + 1, w.end), word: w };
    }).filter(function(x) { return x.char; });
}

function tokenize(rawQuery) {
    var raw = String(rawQuery === undefined || rawQuery === null ? "" : rawQuery);
    var tokens = [];
    var re = /[^\s:/\\|,;]+/g;
    var match;
    while ((match = re.exec(raw)) !== null) {
        var rawToken = match[0];
        var norm = normalizeText(rawToken).trim();
        if (!norm)
            continue;
        tokens.push({ raw: rawToken, normalized: norm, start: match.index, end: match.index + rawToken.length });
    }
    return {
        raw: raw,
        normalized: normalizeText(raw),
        tokens: tokens,
        isEmpty: tokens.length === 0,
        lastTokenEmpty: /\s$/.test(raw) && tokens.length > 0
    };
}

function parseDirective(rawQuery, backends) {
    var raw = String(rawQuery || "");
    var trimmed = raw.replace(/^\s+/, "");
    var directives = [];
    for (var i = 0; i < (backends || []).length; i += 1) {
        var backend = backends[i];
        var prefixes = backend && backend.helpPrefixes ? backend.helpPrefixes : [];
        for (var pi = 0; pi < prefixes.length; pi += 1) {
            directives.push({ prefix: prefixes[pi], backendIds: [backend.backendId], label: backend.helpTitle || backend.name || backend.backendId });
        }
    }
    directives.sort(function(a, b) { return b.prefix.length - a.prefix.length; });

    for (var di = 0; di < directives.length; di += 1) {
        var d = directives[di];
        if (!d.prefix || trimmed.indexOf(d.prefix) !== 0)
            continue;
        var next = trimmed[d.prefix.length];
        var compactPrefix = d.prefix.length === 1 && (d.prefix === ":" || d.prefix === "!");
        if (!compactPrefix && next !== undefined && !/\s/.test(next) && next !== ":" && next !== "/")
            continue;
        return {
            active: true,
            raw: raw,
            searchRaw: trimmed.slice(d.prefix.length).replace(/^[:\s]+/, ""),
            prefix: d.prefix,
            label: d.label,
            tags: [],
            kinds: [],
            backendIds: d.backendIds
        };
    }

    return { active: false, raw: raw, searchRaw: raw, prefix: "", label: "All", tags: [], kinds: [], backendIds: [] };
}

function makeAction(id, label, payload) {
    return { id: id, label: label || id, icon: null, default: false, payload: payload || null };
}

function makeNode(props) {
    var node = props || {};
    if (node.__compositePrepared)
        return node;
    node.id = node.id || "";
    node.backendId = node.backendId || "";
    node.kind = node.kind || "node";
    node.label = node.label || node.title || "";
    node.title = node.label;
    node.subtitle = node.subtitle || "";
    node.icon = node.icon || null;
    node.children = node.children || node._children || [];
    node.aliases = node.aliases || [];
    node.keywords = node.keywords || [];
    node.tags = node.tags || [];
    node.fieldWeights = node.fieldWeights || {};
    node.behavior = node.behavior || {};
    node.semanticTerms = node.semanticTerms || [];
    node.semanticBoostRequiresAny = node.semanticBoostRequiresAny || [];
    node.command = node.command || "";
    node.path = node.path || "";
    node.usageCount = node.usageCount || 0;
    node.lastUsedDaysAgo = node.lastUsedDaysAgo === undefined ? 9999 : node.lastUsedDaysAgo;
    node.evaluationProfile = node.evaluationProfile || { mode: "generic+custom", strategies: ["exact", "prefix", "compact", "substring", "acronym", "semantic", "usage", "recency"], scorePolicy: "default" };
    node.actionList = node.actionList || [];
    node.meta = node.meta || node.metadata || {};
    for (var i = 0; i < node.children.length; i += 1) {
        node.children[i] = makeNode(node.children[i]);
        node.children[i].parent = node;
    }
    node.__compositePrepared = true;
    return node;
}

function countKeys(obj) {
    if (!obj)
        return 0;
    var count = 0;
    for (var key in obj)
        count += 1;
    return count;
}

function nowMs() {
    return Date.now ? Date.now() : new Date().getTime();
}
