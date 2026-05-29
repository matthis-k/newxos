.pragma library

function defaultAction(result) {
  var actions = result && result.actions ? result.actions : [];
  return actions.find(function(a) { return a.default; }) || actions[0] || null;
}

function normalizeAction(action, index) {
  if (!action || !action.id)
    return null;

  return {
    id: action.id,
    label: action.label || action.title || action.id,
    icon: action.icon || null,
    default: !!action.default || index === 0,
    intent: action.intent || null
  };
}

function defaultEnterIntent(result, actions) {
  if (result.enter)
    return result.enter;
  if (result.metadata && result.metadata.replaceQuery)
    return { type: "replace-query", text: result.metadata.replaceQuery };
  return { type: "activate", action: defaultAction({ actions: actions }) };
}

function defaultShiftEnterIntent(result) {
  if (result.shiftEnter)
    return result.shiftEnter;
  if (result.completionText)
    return { type: "replace-query", text: result.completionText };
  if (result.metadata && result.metadata.replaceQuery)
    return { type: "replace-query", text: result.metadata.replaceQuery };
  return { type: "noop" };
}

function normalizeResult(result, fallbackSource) {
  if (!result || !result.id || !result.title)
    return null;

  var actions = (result.actions || []).map(normalizeAction).filter(Boolean);
  if (actions.length === 0)
    return null;

  if (!actions.some(function(a) { return a.default; }))
    actions[0].default = true;

  return {
    id: result.id,
    source: result.source || result.backend || fallbackSource || "",
    title: result.title,
    subtitle: result.subtitle || null,
    description: result.description || null,
    breadcrumbs: Array.isArray(result.path) ? result.path : Array.isArray(result.breadcrumbs) ? result.breadcrumbs : null,
    icon: result.icon || null,
    relevance: Number(result.score || result.relevance || 0),
    category: result.category || null,
    actions: actions,
    children: result.children || [],
    enter: defaultEnterIntent(result, actions),
    shiftEnter: defaultShiftEnterIntent(result),
    executable: result.executable !== undefined ? !!result.executable : !(result.metadata && result.metadata.replaceQuery),
    expandable: !!result.expandable || !!result.completionText || !!(result.metadata && result.metadata.replaceQuery),
    dangerous: !!result.dangerous,
    score: Number(result.score || 0),
    evidence: result.evidence || null,
    onComplete: typeof result.onComplete === 'function' ? result.onComplete : null,
    metadata: result.metadata || null
  };
}

function normalizeResults(results, fallbackSource) {
  return (results || []).map(function(r) { return normalizeResult(r, fallbackSource); }).filter(Boolean);
}

function searchCandidateToResult(candidate) {
  if (!candidate || !candidate.id || !candidate.title)
    return null;

  var result = {
    id: candidate.id,
    source: candidate.backend || "",
    title: candidate.title,
    subtitle: candidate.subtitle || null,
    description: candidate.description || null,
    breadcrumbs: Array.isArray(candidate.path) ? candidate.path : null,
    icon: candidate.icon || null,
    relevance: candidate.score || 0,
    actions: [],
    children: [],
    enter: candidate.enter || { type: "activate", action: candidate.action || candidate.defaultAction || null },
    shiftEnter: { type: "noop" },
    executable: true,
    expandable: false,
    dangerous: !!candidate.dangerous,
    score: candidate.score || 0,
    evidence: candidate.evidence || null,
    onComplete: typeof candidate.onComplete === 'function' ? candidate.onComplete : null,
    metadata: candidate.metadata || {},
    path: Array.isArray(candidate.path) ? candidate.path : null
  };

  var actions = candidate.actions || [];
  if (candidate.action)
    actions.unshift({ id: candidate.action.id, label: candidate.action.title || "Run", icon: "system-run", default: true });

  result.actions = actions.map(normalizeAction).filter(Boolean);
  if (result.actions.length === 0)
    return null;
  if (!result.actions.some(function(a) { return a.default; }))
    result.actions[0].default = true;

  result.enter = defaultEnterIntent(result, result.actions);
  return result;
}
