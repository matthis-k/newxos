.pragma library

var ENABLED = true;
var logs = [];

function enable() {
  ENABLED = true;
}

function disable() {
  ENABLED = false;
}

function log(category, message, data) {
  if (!ENABLED)
    return;

  var entry = {
    timestamp: new Date().toISOString(),
    category: category,
    message: message,
    data: data || null
  };
  logs.push(entry);
  console.warn("[SEARCH:" + category + "]", message, data ? JSON.stringify(data).slice(0, 500) : "");
}

function clear() {
  logs = [];
}

function getLogs() {
  return logs.slice();
}

function getLogsByCategory(category) {
  return logs.filter(function(l) { return l.category === category; });
}

function printSummary() {
  if (!ENABLED) return;
  console.warn("[SEARCH] === Search Debug Summary ===");
  console.warn("[SEARCH] Total log entries:", logs.length);
  for (var ci in categories) {
    var count = logs.filter(function(l) { return l.category === categories[ci]; }).length;
    if (count > 0)
      console.warn("[SEARCH]  " + categories[ci] + ":", count);
  }
  console.warn("[SEARCH] ============================");
}

var categories = [
  "query",
  "profile",
  "router",
  "backend",
  "traversal",
  "scoring",
  "evidence",
  "threshold",
  "execute",
  "error"
];

function logQuery(parsed) {
  log("query", "Parsed query", {
    raw: parsed.raw,
    prefix: parsed.prefix,
    body: parsed.body,
    tokens: parsed.tokens,
    backendFilter: parsed.backendFilter,
    explicitPathMode: parsed.explicitPathMode
  });
}

function logProfile(profile, backends) {
  log("profile", "Selected profile", {
    profile: profile,
    backends: backends
  });
}

function logRouter(backendId, route, routedText) {
  log("router", "Route matched", {
    backend: backendId,
    routeMode: route ? route.mode : "none",
    routedText: routedText
  });
}

function logTraversal(backendId, nodeId, title, score, depth) {
  log("traversal", "Node visited", {
    backend: backendId,
    id: nodeId,
    title: title,
    score: score,
    depth: depth
  });
}

function logCandidate(candidate) {
  log("scoring", "Candidate scored", {
    id: candidate.id,
    title: candidate.title,
    backend: candidate.backend,
    score: candidate.score,
    evidence: candidate.evidence ? candidate.evidence.totalEvidence : null
  });
}

function logEvidenceBreakdown(candidateId, evidence) {
  log("evidence", "Evidence breakdown for " + candidateId, evidence);
}

function logThreshold(candidateId, score, passed) {
  log("threshold", "Threshold check", {
    id: candidateId,
    score: score,
    passed: passed
  });
}

function logExecute(candidateId, actionId, dryRun, safe) {
  log("execute", "Execution attempt", {
    candidateId: candidateId,
    actionId: actionId,
    dryRun: dryRun,
    safe: safe
  });
}

function logError(message, error) {
  log("error", message, {
    error: error ? error.toString() : null
  });
}
