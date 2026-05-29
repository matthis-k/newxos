import QtQml

LauncherBackendBase {
    id: root

    function scoreItem(item, queryText, route) {
        return 0;
    }

    function itemToResult(item, queryText, score, route) {
        return null;
    }

    function itemTitle(item) {
        return item && item.title ? item.title : "";
    }

    function itemSubtitle(item) {
        return item && item.subtitle ? item.subtitle : "";
    }

    function filterAndScore(items, queryText, route) {
        const matches = [];
        const limit = root.maxResults;

        for (const item of items || []) {
            if (!item)
                continue;

            if (!queryText) {
                const result = itemToResult(item, queryText, 8, route);
                if (result)
                    matches.push(result);
                continue;
            }

            const score = scoreItem(item, queryText, route);
            if (score <= 0)
                continue;

            const result = itemToResult(item, queryText, score, route);
            if (result)
                matches.push(result);
        }

        matches.sort((a, b) => b.relevance - a.relevance || a.title.localeCompare(b.title));
        return matches.slice(0, limit);
    }
}
