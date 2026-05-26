.pragma library

function normalize(text) {
    return (text || "").toString().toLowerCase().trim();
}

function fuzzyScore(query, title, subtitle) {
    const q = normalize(query);
    const t = normalize(title);
    const s = normalize(subtitle);

    if (!q || !t)
        return 0;

    if (t === q)
        return 50;

    if (t.startsWith(q))
        return 35;

    if (t.indexOf(q) >= 0)
        return 20;

    if (s.indexOf(q) >= 0)
        return 8;

    let index = 0;
    for (let i = 0; i < t.length && index < q.length; i += 1) {
        if (t[i] === q[index])
            index += 1;
    }

    return index === q.length ? Math.max(4, 14 - (t.length - q.length)) : 0;
}

function score(result, query, backendPriority, parsedQuery) {
    if (!result)
        return 0;

    const relevance = Number(result.relevance || 0) * 100;
    const priority = Number(backendPriority || 0);
    const queryText = parsedQuery && parsedQuery.text ? parsedQuery.text : query;
    let value = priority + relevance + fuzzyScore(queryText, result.title, result.subtitle);

    if (parsedQuery && parsedQuery.explicit) {
        value += result.source === parsedQuery.targetBackend ? 300 : -100;
    }

    if (result.source === "web" && !(parsedQuery && parsedQuery.targetBackend === "web"))
        value -= 40;

    if (result.source === "calculator")
        value += 180;

    return value;
}

function sortResults(results, query, priorityForSource, parsedQuery) {
    return (results || []).slice().sort((a, b) => {
        const scoreA = score(a, query, priorityForSource(a.source), parsedQuery);
        const scoreB = score(b, query, priorityForSource(b.source), parsedQuery);
        if (scoreB !== scoreA)
            return scoreB - scoreA;
        return (a.title || "").localeCompare(b.title || "");
    });
}
