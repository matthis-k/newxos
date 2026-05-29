.pragma library
Qt.include("FieldNormalizer.js")
Qt.include("EvidenceScorer.js")
Qt.include("DebugLogger.js")
Qt.include("StableIdGenerator.js")

var SEARCH_PROFILES = {
  "general": { backends: ["apps", "actions", "calculator"], semantic: false },
  "apps": { backends: ["apps"], semantic: false },
  "actions": { backends: ["actions"], semantic: false },
  "calculator": { backends: ["calculator"], semantic: false },
  "debug-fixture": { backends: ["fixture-apps", "fixture-actions"], semantic: false }
};

var PREFIX_TO_BACKEND = {
  ":": "desktop-actions",
  "!": "desktop-actions",
  "=": "calculator",
  ">": "shell",
  "?": "backends",
  "@app": "desktop",
  "@apps": "desktop",
  "@desktop": "desktop",
  "@calc": "calculator",
  "@calculator": "calculator",
  "@web": "web",
  "@file": "files",
  "@files": "files"
};

function getProfileForPrefix(prefix) {
  if (!prefix) return "general";
  return SEARCH_PROFILES[prefix] ? prefix : "general";
}

function selectBackendsFromPrefix(prefix, allBackends) {
  if (!prefix || !PREFIX_TO_BACKEND[prefix])
    return allBackends || [];
  var targetId = PREFIX_TO_BACKEND[prefix];
  var result = [];
  for (var i = 0; i < (allBackends || []).length; i += 1) {
    var b = allBackends[i];
    if (b && b.backendId === targetId)
      result.push(b);
  }
  return result;
}

function normalizeBackendResult(raw, parsedQuery, backendId) {
  if (!raw || !raw.id || !raw.title)
    return null;
  var path = raw.breadcrumbs || raw.path || [];
  var action = raw.action || raw.defaultAction || null;
  return {
    id: raw.id,
    backend: raw.source || raw.backend || backendId || "",
    kind: raw.kind || (raw.metadata && raw.metadata.kind) || "action",
    title: raw.title,
    subtitle: raw.subtitle || null,
    description: raw.description || null,
    icon: raw.icon || null,
    path: path,
    action: action ? { id: action.actionId || action.id, title: action.title || "" } : null,
    defaultAction: raw.defaultAction ? { id: raw.defaultAction.actionId || raw.defaultAction.id, title: raw.defaultAction.title || "" } : null,
    actions: raw.actions || [],
    aliases: raw.aliases || null,
    keywords: raw.keywords || null,
    dangerous: !!raw.dangerous,
    score: raw.score || 0,
    evidence: raw.evidence || null,
    depth: path.length,
    enter: raw.enter || null,
    onComplete: typeof raw.onComplete === 'function' ? raw.onComplete : null,
    tokenScores: raw.tokenScores || null,
    metadata: raw.metadata || null
  };
}

function search(backends, parsedQuery, context) {
  clear();
  logQuery(parsedQuery);

  if (!parsedQuery || (!parsedQuery.body && !parsedQuery.raw))
    return [];

  var selectedBackends = parsedQuery.prefix
    ? selectBackendsFromPrefix(parsedQuery.prefix, backends)
    : (backends || []);

  logProfile(context && context.profile || "general",
    (selectedBackends || []).map(function(b) { return b ? b.backendId : null; }));
  log("search", "Selected backends for prefix: " + (parsedQuery.prefix || "none"), selectedBackends.length);

  var allCandidates = [];

  for (var bi = 0; bi < (selectedBackends || []).length; bi += 1) {
    var backend = selectedBackends[bi];
    if (!backend || !backend.enabled)
      continue;

    logRouter(backend.backendId, null, parsedQuery.body);

    try {
      if (backend.results) {
        var raw = backend.results(parsedQuery.body || parsedQuery.raw || "");
        if (raw && raw.length > 0) {
          for (var ri = 0; ri < raw.length; ri += 1) {
            var candidate = normalizeBackendResult(raw[ri], parsedQuery, backend.backendId);
            if (candidate)
              allCandidates.push(candidate);
          }
        }
      }
    } catch (e) {
      logError("Backend " + backend.backendId + " failed", e);
    }
  }

  if (allCandidates.length === 0 && (!parsedQuery.prefix || parsedQuery.prefix === "")) {
    for (var fi = 0; fi < (backends || []).length; fi += 1) {
      var fb = backends[fi];
      if (!fb || !fb.enabled || selectedBackends.indexOf(fb) >= 0)
        continue;
      var hasFallback = false;
      if (fb.routes) {
        for (var ri2 = 0; ri2 < fb.routes.length; ri2 += 1) {
          if (fb.routes[ri2].mode === "fallback") {
            hasFallback = true;
            break;
          }
        }
      }
      if (!hasFallback) continue;
      try {
        if (fb.results) {
          var fallbackRaw = fb.results(parsedQuery.body || parsedQuery.raw || "");
          if (fallbackRaw && fallbackRaw.length > 0) {
            for (var fbi = 0; fbi < fallbackRaw.length; fbi += 1) {
              var fc = normalizeBackendResult(fallbackRaw[fbi], parsedQuery, fb.backendId);
              if (fc)
                allCandidates.push(fc);
            }
          }
        }
      } catch (e) {
        logError("Fallback backend " + fb.backendId + " failed", e);
      }
    }
  }

  var bestScore = 0;
  for (var ci = 0; ci < allCandidates.length; ci += 1) {
    var evidence = computeEvidenceBreakdown(allCandidates[ci], parsedQuery, { backendPreferences: {} });
    allCandidates[ci].score = evidence.score;
    allCandidates[ci].evidence = evidence;
    logCandidate(allCandidates[ci]);
    if (evidence.score > bestScore)
      bestScore = evidence.score;
  }

  var thresholded = [];
  for (var ti = 0; ti < allCandidates.length; ti += 1) {
    var passes = isAboveThreshold(allCandidates[ti], bestScore);
    logThreshold(allCandidates[ti].id, allCandidates[ti].score, passes);
    if (passes)
      thresholded.push(allCandidates[ti]);
  }

  thresholded.sort(function(a, b) {
    if (b.score !== a.score)
      return b.score - a.score;
    return (a.title || "").localeCompare(b.title || "");
  });

  var limit = context && context.maxResults ? context.maxResults : 50;
  var finalResults = thresholded.slice(0, limit);

  printSummary();
  return finalResults;
}

function debugSearch(backends, query, context) {
  var parsed = parseQuery(query);
  enable();
  clear();
  logQuery(parsed);

  var result = search(backends, parsed, context || {});

  var output = {
    parsedQuery: parsed,
    resultCount: result.length,
    results: result.slice(0, 10).map(function(r) {
      return {
        id: r.id,
        title: r.title,
        path: r.path,
        backend: r.backend,
        kind: r.kind,
        score: r.score,
        band: scoreToBand(r.score),
        evidence: r.evidence ? {
          totalEvidence: r.evidence.totalEvidence,
          score: r.evidence.score,
          positive: r.evidence.positive,
          negative: r.evidence.negative
        } : null,
        dangerous: r.dangerous,
        safeToExecute: isSafeToExecute(r)
      };
    }),
    logs: getLogs()
  };
  return output;
}

function parseQuery(query) {
  var raw = String(query || "").trim();
  if (!raw)
    return { raw: "", body: "", prefix: null, tokens: [], backendFilter: null, explicitPathMode: false };

  var prefix = null;
  var body = raw;

  var namedPrefixes = ["@app", "@apps", "@desktop", "@calc", "@calculator", "@web", "@file", "@files", "@ddg", "@gh", "@yt", "@g"];
  var sortedNamed = namedPrefixes.slice().sort(function(a, b) { return b.length - a.length; });

  for (var ni = 0; ni < sortedNamed.length; ni += 1) {
    var np = sortedNamed[ni];
    if (raw === np) {
      prefix = np;
      body = "";
      break;
    }
    if (raw.startsWith(np)) {
      var nextChar = raw[np.length];
      if (nextChar === undefined || /\s/.test(nextChar) || nextChar === ":" || nextChar === "/") {
        prefix = np;
        body = raw.slice(np.length).replace(/^[:\s]+/, "");
        break;
      }
    }
  }

  if (!prefix) {
    var symbolicPrefixes = [":", "=", ">", "?"];
    for (var si = 0; si < symbolicPrefixes.length; si += 1) {
      var sp = symbolicPrefixes[si];
      if (raw.startsWith(sp)) {
        prefix = sp;
        body = raw.slice(sp.length).replace(/^\s+/, "");
        break;
      }
    }
  }

  var toks = tokenize(body);
  var hasPathSep = body.indexOf("/") >= 0 || body.indexOf("\u203A") >= 0;

  return {
    raw: raw,
    body: body,
    prefix: prefix,
    tokens: toks,
    backendFilter: prefix ? [PREFIX_TO_BACKEND[prefix]].filter(Boolean) : null,
    explicitPathMode: hasPathSep
  };
}
