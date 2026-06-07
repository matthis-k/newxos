.pragma library
.import "CompositeSearchText.js" as Text
.import "CompositeSearchIndex.js" as Index
.import "CompositeSearchEvidence.js" as Evidence
.import "CompositeSearchEvaluate.js" as Evaluate
.import "CompositeSearchPolicyRegistry.js" as Registry


var clamp = Text.clamp;
var fuzzyDistanceLimit = Text.fuzzyDistanceLimit;
var boundedDamerauLevenshtein = Text.boundedDamerauLevenshtein;
var searchableFields = Index.searchableFields;
var matchField = Evidence.matchField;
var matchSemantic = Evidence.matchSemantic;
var claimMatchingTokens = Evidence.claimMatchingTokens;
var tokenClaimToEvidence = Evidence.tokenClaimToEvidence;
var scoreEvidence = Evidence.scoreEvidence;
var recencyScore = Evidence.recencyScore;
var frequencyScore = Evidence.frequencyScore;
var filterFields = Evidence.filterFields;
var fuzzyAliasScore = Evaluate.fuzzyAliasScore;
var collectParentChain = Evaluate.collectParentChain;


function splitOnUnescaped(str, sep) {
    var out = [];
    var cur = "";
    for (var i = 0; i < str.length; i += 1) {
        if (str[i] === "\\" && i + 1 < str.length) {
            cur += str[i + 1];
            i += 1;
        } else if (str[i] === sep) {
            out.push(cur);
            cur = "";
        } else {
            cur += str[i];
        }
    }
    out.push(cur);
    return out;
}

function unescape(str) {
    var out = "";
    for (var i = 0; i < str.length; i += 1) {
        if (str[i] === "\\" && i + 1 < str.length) {
            out += str[i + 1];
            i += 1;
        } else {
            out += str[i];
        }
    }
    return out;
}

function parsePolicyName(name) {
    var parts = splitOnUnescaped(name, ":");
    return { base: unescape(parts[0]), params: parts.slice(1).map(unescape) };
}

// ── Field Match (evidence, group: own or inherited) ──

function makeFieldMatchPolicy(name) {
    var parsed = parsePolicyName(name);
    var filterType = parsed.params[0] || "all";
    var group = filterType === "breadcrumb" ? "inherited" : "own";

    var strategies = ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"];
    if (parsed.params.length >= 2) {
        var s = parsed.params.slice(1).join(",");
        strategies = s.split(",").map(function(x) { return x.trim(); }).filter(Boolean);
    }

    return {
        name: name,
        phase: "evidence",
        group: group,
        match: function(node, query, ctx) {
            if (query.isEmpty)
                return [];
            var fields = searchableFields(node);
            var filtered = filterFields(fields, filterType);
            var out = [];
            for (var fi = 0; fi < filtered.length; fi += 1)
                out = out.concat(matchField(filtered[fi], query, strategies));
            return out;
        }
    };
}

// ── Switch Action (evidence, group: own) ──

function makeSwitchActionEvidencePolicy() {
    return {
        name: "switch-action",
        phase: "evidence",
        group: "own",
        match: function(node, query, ctx) {
            return switchActionEvidenceInner(node, query);
        }
    };
}

function switchActionEvidenceInner(node, query) {
    if (!node.switchActions || query.isEmpty)
        return [];
    var aliasMap = {
        on: ["on", "enable", "connect"],
        off: ["off", "disable", "disconnect"],
        toggle: ["toggle", "switch"]
    };
    var acronym = String(node.label || "").replace(/[^A-Za-z0-9]/g, "").charAt(0).toLowerCase();
    if (acronym) {
        aliasMap.on.push(acronym + "o");
        aliasMap.off.push(acronym + "f");
        aliasMap.toggle.push(acronym + "t");
    }
    var out = [];
    for (var ti = 0; ti < query.tokens.length; ti += 1) {
        var token = query.tokens[ti].normalized;
        for (var actionId in aliasMap) {
            if (!node.switchActions[actionId])
                continue;
            for (var ai = 0; ai < aliasMap[actionId].length; ai += 1) {
                var alias = aliasMap[actionId][ai];
                var fs = fuzzyAliasScore(token, alias);
                var score = token === alias ? 1.0 : alias.indexOf(token) === 0 && token.length >= 2 ? 0.78 : alias.length > token.length && alias.lastIndexOf(token) === alias.length - token.length ? 0.65 : fs;
                if (score > 0)
                    out.push({ strategy: "switch-action", field: "action", fieldText: alias, nodeId: node.id, originNodeId: node.id, originKind: "self", depth: 0, tokenIndex: ti, tokenIndexes: [ti], coverageCount: 1, exactness: score >= 1 ? "exact" : fs > 0 ? "fuzzy" : "prefix", actionId: actionId, actionRole: "switch-" + actionId, isExecutable: true, kind: score >= 1 ? "action-exact" : fs > 0 ? "action-fuzzy" : "action-prefix", score: score, weight: fs > 0 ? 0.42 : 0.64, effective: score * (fs > 0 ? 0.42 : 0.64), ranges: [], reason: fs > 0 ? "switch action alias fuzzy match" : "switch action alias" });
            }
        }
    }
    return out;
}

// ── Switch Aliases Boost (boost phase) ──

function makeSwitchAliasesBoostPolicy() {
    return {
        name: "switch-aliases",
        phase: "boost",
        apply: function(node, query, ctx, evaluatedChildren, scores) {
            if (!node.switchActions || !scores || !scores.ownScore || scores.ownScore <= 0)
                return 0;
            return computeSwitchAliasesBoost(node, query, ctx);
        }
    };
}

function computeSwitchAliasesBoost(node, query, ctx) {
    if (!node.switchActions || query.isEmpty)
        return 0;
    var aliasMap = {
        on: ["on", "enable", "connect"],
        off: ["off", "disable", "disconnect"],
        toggle: ["toggle", "switch"]
    };
    var acronym = String(node.label || "").replace(/[^A-Za-z0-9]/g, "").charAt(0).toLowerCase();
    if (acronym) {
        aliasMap.on.push(acronym + "o");
        aliasMap.off.push(acronym + "f");
        aliasMap.toggle.push(acronym + "t");
    }
    var bestTokenScore = 0;
    for (var ti = 0; ti < query.tokens.length; ti += 1) {
        var token = query.tokens[ti].normalized;
        for (var actionId in aliasMap) {
            for (var ai = 0; ai < aliasMap[actionId].length; ai += 1) {
                var alias = aliasMap[actionId][ai];
                var score = token === alias ? 1.0 : alias.indexOf(token) === 0 && token.length >= 2 ? 0.78 : alias.length > token.length && alias.lastIndexOf(token) === alias.length - token.length ? 0.65 : fuzzyAliasScore(token, alias);
                bestTokenScore = Math.max(bestTokenScore, score);
            }
        }
    }
    return bestTokenScore;
}

// ── Semantic (evidence, group: own) ──

function makeSemanticPolicy() {
    return {
        name: "semantic",
        phase: "evidence",
        group: "own",
        match: function(node, query, ctx) {
            return matchSemantic(node, query);
        }
    };
}

// ── Token Claim (evidence, group: own) ──

function makeTokenClaimPolicy() {
    return {
        name: "token-claim",
        phase: "evidence",
        group: "own",
        match: function(node, query, ctx) {
            if (!node.behavior || !node.behavior.tokenPolicy || !node.behavior.tokenPolicy.tokens || query.isEmpty)
                return [];
            var claims = claimMatchingTokens(query, node.behavior.tokenPolicy.tokens, node.behavior.tokenPolicy);
            var out = [];
            for (var ci = 0; ci < claims.length; ci += 1)
                out.push(tokenClaimToEvidence(node, query, claims[ci]));
            return out;
        }
    };
}

// ── Usage (evidence, group: own) ──

function makeUsagePolicy() {
    return {
        name: "usage",
        phase: "evidence",
        group: "own",
        match: function(node, query, ctx) {
            if (query.isEmpty || !node.usageCount || node.usageCount <= 0)
                return [];
            var usage = frequencyScore(node.usageCount);
            return [{ strategy: "usage", field: "usage", fieldText: String(node.usageCount), nodeId: node.id, kind: "frequency", score: usage, weight: 0.12, effective: usage * 0.12, ranges: [], reason: "usage frequency" }];
        }
    };
}

// ── Recency (evidence, group: own) ──

function makeRecencyPolicy() {
    return {
        name: "recency",
        phase: "evidence",
        group: "own",
        match: function(node, query, ctx) {
            if (query.isEmpty || !isFinite(node.lastUsedDaysAgo))
                return [];
            var rec = recencyScore(node.lastUsedDaysAgo);
            return [{ strategy: "recency", field: "recency", fieldText: String(node.lastUsedDaysAgo), nodeId: node.id, kind: "recency", score: rec, weight: 0.08, effective: rec * 0.08, ranges: [], reason: "last used" }];
        }
    };
}

// ── Path Evidence (inherit phase) ──

function makePathEvidencePolicy() {
    return {
        name: "path-evidence",
        phase: "inherit",
        apply: function(evaluated, query, ctx) {
            if (evaluated.node.kind === "root" || evaluated.node.kind === "backend")
                return;
            var inherited = pathEvidenceFromAncestorsInner(evaluated.node, query, ctx);
            if (!inherited.length)
                return;

            var directTokens = {};
            for (var ei = 0; ei < (evaluated.ownEvidence || []).length; ei += 1) {
                var covered = Evidence.inferCoveredTokenIndexes(evaluated.ownEvidence[ei], query);
                for (var ci = 0; ci < covered.length; ci += 1) {
                    if (typeof covered[ci] === "number")
                        directTokens[covered[ci]] = true;
                }
            }

            var filtered = inherited.filter(function(e) {
                var covered = Evidence.inferCoveredTokenIndexes(e, query);
                for (var ci = 0; ci < covered.length; ci += 1) {
                    if (typeof covered[ci] === "number" && directTokens[covered[ci]])
                        return false;
                }
                return true;
            });

            if (!filtered.length)
                return;

            var mapped = filtered.map(function(e) {
                return Object.assign({}, e, { kind: "path-" + e.kind, originKind: "ancestor", depth: -1, weight: e.weight * 0.7, effective: e.score * e.weight * 0.7 });
            });

            var addedInherited = evaluated.inheritedEvidence || [];
            addedInherited = addedInherited.concat(mapped);
            evaluated.inheritedEvidence = addedInherited;
            evaluated.evidence = (evaluated.ownEvidence || []).concat(addedInherited);

            var inheritedResult = scoreEvidence(addedInherited, evaluated.node, ctx);
            evaluated.inheritedScore = clamp(Math.max(evaluated.inheritedScore || 0, inheritedResult.value));
            evaluated.score = clamp(Math.max(evaluated.ownScore || 0, evaluated.inheritedScore, evaluated.descendantScore || 0));
            evaluated.visible = evaluated.visible || inheritedResult.visible;
        }
    };
}

function pathEvidenceFromAncestorsInner(node, query, ctx) {
    if (!ctx.includePath || query.isEmpty)
        return [];
    var chain = collectParentChain(node).slice(0, -1);
    var out = [];
    var weight = 0.24;
    for (var i = 0; i < chain.length; i += 1) {
        var fields = searchableFields(chain[i]).filter(function(f) {
            return ["label", "aliases", "keywords"].indexOf(f.field) >= 0;
        });
        for (var fi = 0; fi < fields.length; fi += 1) {
            var inherited = Object.assign({}, fields[fi], { field: "ancestor-" + fields[fi].field, weight: weight * Math.min(1, fields[fi].weight) });
            out = out.concat(matchField(inherited, query, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"]));
        }
        weight *= 0.72;
    }
    return out;
}

// ── Descendant Boost (boost phase) ──

function makeDescendantBoostPolicy(name) {
    var parsed = parsePolicyName(name);
    var factorParam = parsed.params[0] || "auto";

    return {
        name: name,
        phase: "boost",
        apply: function(node, query, ctx, evaluatedChildren, scores) {
            var directiveActive = !!(ctx.directive && ctx.directive.active);
            var ownScore = scores ? scores.ownScore || 0 : 0;
            var groupDisplay = node.behavior && node.behavior.flattenPolicy && node.behavior.flattenPolicy.groupDisplay || {};
            var keepAllChildren = (groupDisplay.showAllChildrenOnParentMatch || groupDisplay.flattenAllChildrenOnParentMatch) && false;

            var retained = (evaluatedChildren || []).filter(function(c) {
                return keepAllChildren || c.candidate || c.visible || ctx.showHidden;
            });

            var bestChildScore = 0;
            var bestChildMatchDepth = 9999;
            for (var b = 0; b < retained.length; b += 1) {
                if (retained[b].visible || ctx.showHidden) {
                    if (retained[b].score > bestChildScore + 0.0001) {
                        bestChildScore = retained[b].score;
                        bestChildMatchDepth = (retained[b].matchDepth === undefined ? 0 : retained[b].matchDepth) + 1;
                    } else if (Math.abs(retained[b].score - bestChildScore) <= 0.0001) {
                        bestChildMatchDepth = Math.min(bestChildMatchDepth, (retained[b].matchDepth === undefined ? 0 : retained[b].matchDepth) + 1);
                    }
                }
            }
            if (bestChildScore <= 0)
                return 0;

            var depthPenalty = bestChildMatchDepth < 9999 ? Math.pow(0.92, bestChildMatchDepth) : 1;
            var factor;
            if (factorParam !== "auto") {
                factor = parseFloat(factorParam);
                factor = isFinite(factor) ? clamp(factor, 0, 1) : 0.28;
            } else {
                factor = node.switchActions ? (ownScore > 0 ? 1 : 0.82) : node.kind === "backend" ? 0.82 : node.behavior && node.behavior.filterable ? 1.0 : 0.28;
            }

            return bestChildScore * depthPenalty * factor;
        }
    };
}

// ── Child Visible (child-visible phase) ──

function makeChildVisiblePolicy(name) {
    var parsed = parsePolicyName(name);
    var checkType = parsed.params[0] || "visible-flag";
    var threshold = parsed.params.length >= 2 ? parseFloat(parsed.params[1]) : 0;
    if (!isFinite(threshold))
        threshold = 0;

    return {
        name: name,
        phase: "child-visible",
        apply: function(childEval, parentEval, ctx) {
            switch (checkType) {
                case "visible-flag":
                    return childEval.visible === true;
                case "has-own-score":
                    return (childEval.ownScore || 0) > 0;
                case "own-score-beats-parent":
                    return (childEval.ownScore || 0) > (parentEval.ownScore || 0);
                case "above-min-score":
                    return (childEval.score || 0) >= threshold;
                case "own-score-min":
                    return (childEval.ownScore || 0) >= threshold;
                case "candidate-or-visible":
                    return childEval.candidate === true || childEval.visible === true;
                case "has-evidence":
                    return (childEval.ownEvidence || []).length > 0 || (childEval.inheritedEvidence || []).length > 0;
                default:
                    return childEval.visible === true;
            }
        }
    };
}

// ── Child Bypass (child-bypass phase) ──

function makeChildBypassPolicy(name) {
    var parsed = parsePolicyName(name);
    var checkType = parsed.params[0] || "score-dominates";
    var margin = parsed.params.length >= 2 ? parseFloat(parsed.params[1]) : 0.03;
    if (!isFinite(margin))
        margin = 0.03;

    return {
        name: name,
        phase: "child-bypass",
        apply: function(childEval, parentEval, ctx) {
            switch (checkType) {
                case "score-dominates":
                    return (childEval.score || 0) >= (parentEval.score || 0) + margin;
                case "own-score-dominates":
                    return (childEval.ownScore || 0) >= (parentEval.ownScore || 0) + margin;
                case "score-beats-parent":
                    return (childEval.score || 0) > (parentEval.score || 0);
                case "own-score-beats-parent":
                    return (childEval.ownScore || 0) > (parentEval.ownScore || 0);
                default:
                    return (childEval.score || 0) >= (parentEval.score || 0) + margin;
            }
        }
    };
}

// ── Module-level built-in registration ──

Registry.evidence.register("field-match:all", makeFieldMatchPolicy("field-match:all"));
Registry.evidence.register("field-match:primary", makeFieldMatchPolicy("field-match:primary"));
Registry.evidence.register("field-match:breadcrumb", makeFieldMatchPolicy("field-match:breadcrumb"));
Registry.evidence.register("switch-action", makeSwitchActionEvidencePolicy());
Registry.evidence.register("semantic", makeSemanticPolicy());
Registry.evidence.register("token-claim", makeTokenClaimPolicy());
Registry.evidence.register("usage", makeUsagePolicy());
Registry.evidence.register("recency", makeRecencyPolicy());

Registry.inherit.register("path-evidence", makePathEvidencePolicy());

Registry.boost.register("descendant-boost", makeDescendantBoostPolicy("descendant-boost"));
Registry.boost.register("switch-aliases", makeSwitchAliasesBoostPolicy());

Registry.childVisible.register("visible-flag", makeChildVisiblePolicy("visible-flag"));
Registry.childVisible.register("has-own-score", makeChildVisiblePolicy("has-own-score"));
Registry.childVisible.register("own-score-beats-parent", makeChildVisiblePolicy("own-score-beats-parent"));
Registry.childVisible.register("above-min-score:0.25", makeChildVisiblePolicy("above-min-score:0.25"));
Registry.childVisible.register("own-score-min:0.25", makeChildVisiblePolicy("own-score-min:0.25"));
Registry.childVisible.register("candidate-or-visible", makeChildVisiblePolicy("candidate-or-visible"));

Registry.childBypass.register("own-score-beats-parent", makeChildBypassPolicy("own-score-beats-parent"));
Registry.childBypass.register("score-dominates:0.03", makeChildBypassPolicy("score-dominates:0.03"));
Registry.childBypass.register("score-dominates:0.08", makeChildBypassPolicy("score-dominates:0.08"));
Registry.childBypass.register("own-score-dominates:0.08", makeChildBypassPolicy("own-score-dominates:0.08"));
