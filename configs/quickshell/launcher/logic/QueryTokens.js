.pragma library

function tokens(query) {
    return String(query || "").trim().split(/\s+/).filter(token => token.length > 0);
}

function bodyTokens(query, prefix) {
    const all = tokens(query);
    if (!prefix || all.length === 0)
        return all;
    return all[0] === prefix ? all.slice(1) : all;
}

function textFromTokens(items) {
    return (items || []).join(" ");
}
