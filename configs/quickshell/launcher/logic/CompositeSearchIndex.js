.pragma library
.import "CompositeSearchText.js" as Text


var normalizeText = Text.normalizeText;
var splitWordsWithRanges = Text.splitWordsWithRanges;
var compactWithMap = Text.compactWithMap;
var getAcronymRanges = Text.getAcronymRanges;
var fuzzyDistanceLimit = Text.fuzzyDistanceLimit;
var boundedDamerauLevenshtein = Text.boundedDamerauLevenshtein;

function prepareSearchableField(field) {
    var text = String(field.text === undefined || field.text === null ? "" : field.text);
    field.text = text;
    field.normText = normalizeText(text);
    field.words = splitWordsWithRanges(text);
    field.compact = compactWithMap(text);
    field.acronymLetters = getAcronymRanges(text);
    return field;
}

function searchableFields(node) {
    if (node.__searchableFields)
        return node.__searchableFields;
    var w = node.fieldWeights || {};
    var fields = [{ field: "label", text: node.label, weight: w.label === undefined ? 1.0 : w.label, nodeId: node.id }];
    if (node.subtitle) fields.push({ field: "subtitle", text: node.subtitle, weight: w.subtitle === undefined ? 0.55 : w.subtitle, nodeId: node.id });
    if (node.aliases && node.aliases.length) fields.push({ field: "aliases", text: node.aliases.join(" "), weight: w.aliases === undefined ? 0.72 : w.aliases, nodeId: node.id });
    if (node.keywords && node.keywords.length) fields.push({ field: "keywords", text: node.keywords.join(" "), weight: w.keywords === undefined ? 0.45 : w.keywords, nodeId: node.id });
    if (node.command) fields.push({ field: "command", text: node.command, weight: w.command === undefined ? 0.25 : w.command, nodeId: node.id });
    if (node.path) fields.push({ field: "path", text: node.path, weight: w.path === undefined ? 0.38 : w.path, nodeId: node.id });
    node.__searchableFields = fields.map(prepareSearchableField);
    return node.__searchableFields;
}

function addUnique(list, item) {
    if (list.indexOf(item) < 0)
        list.push(item);
}

function addIndexEntry(map, key, node) {
    if (!key)
        return;
    if (!map[key])
        map[key] = [];
    addUnique(map[key], node);
}

function addFieldToIndex(index, field, node) {
    var words = field.words || [];
    for (var wi = 0; wi < words.length; wi += 1) {
        var word = words[wi].norm;
        if (!word)
            continue;
        addIndexEntry(index.exact, word, node);
        addIndexEntry(index.terms, word, node);
        for (var pi = 1; pi <= word.length; pi += 1)
            addIndexEntry(index.prefix, word.slice(0, pi), node);
    }

    var compact = field.compact && field.compact.compact || "";
    if (compact.length >= 2) {
        addIndexEntry(index.compact, compact, node);
        addIndexEntry(index.terms, compact, node);
        for (var cpi = 2; cpi <= compact.length; cpi += 1)
            addIndexEntry(index.compactPrefix, compact.slice(0, cpi), node);
    }

    var acronym = (field.acronymLetters || []).map(function(x) { return x.char; }).join("");
    if (acronym.length >= 2) {
        addIndexEntry(index.acronym, acronym, node);
        for (var api = 2; api <= acronym.length; api += 1)
            addIndexEntry(index.acronymPrefix, acronym.slice(0, api), node);
    }
}

function computeDirectiveTagClosure(node) {
    if (node.__directiveTagClosure)
        return node.__directiveTagClosure;
    var closure = {};
    for (var ti = 0; ti < (node.tags || []).length; ti += 1)
        closure[node.tags[ti]] = true;
    for (var ci = 0; ci < (node.children || []).length; ci += 1) {
        var childClosure = computeDirectiveTagClosure(node.children[ci]);
        for (var key in childClosure)
            closure[key] = true;
    }
    node.__directiveTagClosure = closure;
    return closure;
}

function buildSearchIndex(root) {
    if (root.__searchIndex)
        return root.__searchIndex;

    var index = {
        exact: {},
        prefix: {},
        compact: {},
        compactPrefix: {},
        acronym: {},
        acronymPrefix: {},
        terms: {},
        nodesById: {}
    };

    function mergeMap(target, source) {
        for (var key in source) {
            if (!target[key])
                target[key] = [];
            var nodes = source[key] || [];
            for (var ni = 0; ni < nodes.length; ni += 1)
                addUnique(target[key], nodes[ni]);
        }
    }

    function mergeIndex(source) {
        mergeMap(index.exact, source.exact || {});
        mergeMap(index.prefix, source.prefix || {});
        mergeMap(index.compact, source.compact || {});
        mergeMap(index.compactPrefix, source.compactPrefix || {});
        mergeMap(index.acronym, source.acronym || {});
        mergeMap(index.acronymPrefix, source.acronymPrefix || {});
        mergeMap(index.terms, source.terms || {});
        for (var id in source.nodesById || {})
            index.nodesById[id] = source.nodesById[id];
    }

    function visit(node) {
        if (node !== root && node.__searchIndex) {
            mergeIndex(node.__searchIndex);
            return;
        }
        index.nodesById[node.id] = node;
        var fields = searchableFields(node);
        for (var fi = 0; fi < fields.length; fi += 1)
            addFieldToIndex(index, fields[fi], node);
        for (var ci = 0; ci < (node.children || []).length; ci += 1)
            visit(node.children[ci]);
    }

    visit(root);
    computeDirectiveTagClosure(root);
    root.__searchIndex = index;
    return index;
}

function markNodeAndAncestors(marked, node) {
    var cur = node;
    while (cur) {
        marked[cur.id] = true;
        cur = cur.parent;
    }
}

function markNodeAndDescendants(marked, node) {
    marked[node.id] = true;
    for (var i = 0; i < (node.children || []).length; i += 1)
        markNodeAndDescendants(marked, node.children[i]);
}

function markNodeFamily(marked, node) {
    markNodeAndAncestors(marked, node);
    markNodeAndDescendants(marked, node);
}

function collectIndexHitsCapped(map, key, marked, capState) {
    var nodes = map[key] || [];
    for (var i = 0; i < nodes.length; i += 1) {
        if (capState.hits >= capState.cap)
            return;
        capState.hits += 1;
        markNodeFamily(marked, nodes[i]);
    }
}

function collectFuzzyHitsCapped(index, token, marked, capState) {
    if (String(token || "").length < 3)
        return;
    var maxDistance = 0;
    for (var term in index.terms) {
        if (capState.hits >= capState.cap)
            return;
        maxDistance = fuzzyDistanceLimit(token, term);
        if (Math.abs(term.length - token.length) > maxDistance || term === token)
            continue;
        if (boundedDamerauLevenshtein(token, term, maxDistance) > maxDistance)
            continue;
        collectIndexHitsCapped(index.terms, term, marked, capState);
    }
}

function collectCandidateIds(index, query, marked, capState) {
    if (!index || query.isEmpty)
        return null;

    marked = marked || {};
    capState = capState || { hits: 0, cap: 256 };
    for (var ti = 0; ti < query.tokens.length; ti += 1) {
        if (capState.hits >= capState.cap)
            break;
        var token = query.tokens[ti].normalized;
        var compactToken = compactWithMap(query.tokens[ti].raw).compact || token;
        collectIndexHitsCapped(index.exact, token, marked, capState);
        collectIndexHitsCapped(index.prefix, token, marked, capState);
        collectIndexHitsCapped(index.compact, compactToken, marked, capState);
        collectIndexHitsCapped(index.compactPrefix, compactToken, marked, capState);
        collectIndexHitsCapped(index.acronym, token, marked, capState);
        collectIndexHitsCapped(index.acronymPrefix, token, marked, capState);
        collectFuzzyHitsCapped(index, token, marked, capState);

        // Avoid whole-index substring scans on every keystroke. Exact, prefix,
        // compact, acronym, and capped fuzzy term hits provide the hot-path
        // candidate set; the field matcher still handles substring evidence for
        // those candidates.
    }
    return marked;
}

function collectCandidateIdsForRoots(roots, query, cap) {
    if (query.isEmpty)
        return null;

    var marked = {};
    var capState = { hits: 0, cap: cap || 256 };
    for (var i = 0; i < (roots || []).length; i += 1) {
        if (capState.hits >= capState.cap)
            break;
        collectCandidateIds(buildSearchIndex(roots[i]), query, marked, capState);
    }
    return marked;
}
