.pragma library

function defaultAction(result) {
    const actions = result && result.actions ? result.actions : [];
    return actions.find(action => action.default) || actions[0] || null;
}

function normalizeAction(action, index) {
    if (!action || !action.id || !action.label)
        return null;

    return {
        id: action.id,
        label: action.label,
        icon: action.icon || null,
        default: !!action.default || index === 0
    };
}

function normalizeResult(result, fallbackSource) {
    if (!result || !result.id || !result.title)
        return null;

    const actions = (result.actions || []).map(normalizeAction).filter(Boolean);
    if (actions.length === 0)
        return null;

    if (!actions.some(action => action.default))
        actions[0].default = true;

    return {
        id: result.id,
        source: result.source || fallbackSource || "",
        title: result.title,
        subtitle: result.subtitle || null,
        icon: result.icon || null,
        relevance: Number(result.relevance || 0),
        category: result.category || null,
        actions: actions,
        metadata: result.metadata || null
    };
}

function normalizeResults(results, fallbackSource) {
    return (results || []).map(result => normalizeResult(result, fallbackSource)).filter(Boolean);
}
