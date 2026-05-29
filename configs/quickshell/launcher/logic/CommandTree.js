.pragma library

function normalizeText(text) {
    return (text || "").toString().toLowerCase().trim();
}

function compactForm(text) {
    return normalizeText(text).replace(/[\s-]+/g, "");
}

function tokenizeForMatch(text) {
    var normalized = normalizeText(text);
    var hyphenSplit = normalized.split(/[\s-]+/).filter(function(t) { return t.length > 0; });
    var compacted = compactForm(text);
    var compactTokens = [];
    if (compacted.length > 0 && hyphenSplit.length > 1)
        compactTokens.push(compacted);
    return hyphenSplit.concat(compactTokens);
}

const K = 0.1;

function normalize(raw, context) {
    var fn = context && context.normalize ? context.normalize : function(x) { return x / (x + K); };
    return fn(Math.max(0, raw));
}

function denormalize(norm) {
    return K * norm / (1 - norm);
}

function normalized_add(a, b) {
    return normalize(denormalize(a) + denormalize(b));
}

function isSubsequence(pattern, text) {
    var index = 0;
    for (var i = 0; i < text.length && index < pattern.length; i += 1) {
        if (text[i] === pattern[index])
            index += 1;
    }
    return index === pattern.length;
}

function matchTokens(text, context) {
    var tokens = context.tokens;
    if (!tokens || !tokens.length) return [];
    var sourceTokens = tokenizeForMatch(text);
    var results = [];
    for (var si = 0; si < sourceTokens.length; si += 1) {
        for (var ti = 0; ti < tokens.length; ti += 1) {
            results.push({ source: sourceTokens[si], token: tokens[ti] });
        }
    }
    return results;
}

function createExactScorer() {
    return {
        _score: function(text, context) {
            var tokens = context.tokens;
            if (!tokens || !tokens.length) return 0;
            var candidates = tokenizeForMatch(text);
            var best = 0;
            for (var ci = 0; ci < candidates.length; ci += 1) {
                for (var ti = 0; ti < tokens.length; ti++) {
                    if (tokens[ti] === candidates[ci]) {
                        return 1;
                    }
                }
            }
            return best;
        }
    };
}

function createStartsWithScorer() {
    return {
        _score: function(text, context) {
            var tokens = context.tokens;
            if (!tokens || !tokens.length) return 0;
            var candidates = tokenizeForMatch(text);
            var best = 0;
            for (var ci = 0; ci < candidates.length; ci += 1) {
                for (var ti = 0; ti < tokens.length; ti++) {
                    if (candidates[ci].startsWith(tokens[ti])) {
                        best = Math.max(best, 0.8);
                    }
                }
            }
            return best;
        }
    };
}

function createContainsScorer() {
    return {
        _score: function(text, context) {
            var tokens = context.tokens;
            if (!tokens || !tokens.length) return 0;
            var candidates = tokenizeForMatch(text);
            var best = 0;
            for (var ci = 0; ci < candidates.length; ci += 1) {
                for (var ti = 0; ti < tokens.length; ti++) {
                    if (candidates[ci].indexOf(tokens[ti]) >= 0) {
                        best = Math.max(best, 0.5);
                    }
                }
            }
            return best;
        }
    };
}

function createFuzzyScorer() {
    return {
        _score: function(text, context) {
            var tokens = context.tokens;
            if (!tokens || !tokens.length) return 0;
            var candidates = tokenizeForMatch(text);
            var best = 0;
            for (var ci = 0; ci < candidates.length; ci += 1) {
                for (var ti = 0; ti < tokens.length; ti++) {
                    if (isSubsequence(tokens[ti], candidates[ci])) {
                        best = Math.max(best, 0.25);
                    }
                }
            }
            return best;
        }
    };
}

function createBestOfScorer(scorers) {
    return {
        scorers: scorers,
        _score: function(target, context) {
            var best = 0;
            for (var si = 0; si < this.scorers.length; si++) {
                best = Math.max(best, this.scorers[si]._score(target, context));
            }
            return best;
        }
    };
}

function createWeightedScorer(weightedScorers) {
    return {
        weightedScorers: weightedScorers,
        _score: function(target, context) {
            var sum = 0;
            var totalWeight = 0;
            for (var wi = 0; wi < this.weightedScorers.length; wi++) {
                var entry = this.weightedScorers[wi];
                sum += entry.weight * entry.scorer._score(target, context);
                totalWeight += entry.weight;
            }
            return totalWeight > 0 ? sum / totalWeight : 0;
        }
    };
}

function createPenaltyScorer(base, penaltyFn) {
    return {
        base: base,
        penaltyFn: penaltyFn,
        _score: function(target, context) {
            var raw = this.base._score(target, context);
            var penalty = this.penaltyFn(context);
            return raw * penalty;
        }
    };
}

function nodeNames(node) {
    var names = [];
    if (node.title) names.push(node.title);
    if (node.aliases) names.push.apply(names, node.aliases);
    return names.filter(Boolean);
}

function computeOwnTokenScores(node, tokens) {
    var scores = {};
    var names = nodeNames(node);
    for (var ni = 0; ni < names.length; ni++) {
        var nameTokens = tokenizeForMatch(names[ni]);
        for (var ti = 0; ti < tokens.length; ti++) {
            var token = tokens[ti];
            var best = 0;
            for (var nti = 0; nti < nameTokens.length; nti++) {
                if (nameTokens[nti] === token) { best = Math.max(best, 1); }
                else if (nameTokens[nti].startsWith(token)) { best = Math.max(best, 0.8); }
                else if (nameTokens[nti].indexOf(token) >= 0) { best = Math.max(best, 0.5); }
            }
            scores[token] = Math.max(scores[token] || 0, best);
        }
    }
    return scores;
}

function combineTokenScores(parentScores, ownScores) {
    var combined = {};
    if (parentScores) {
        for (var key in parentScores)
            combined[key] = parentScores[key] * 0.4;
    }
    if (ownScores) {
        for (var key in ownScores)
            combined[key] = Math.max(combined[key] || 0, ownScores[key]);
    }
    return combined;
}

function createNodeScorer(stringScorer) {
    return {
        stringScorer: stringScorer,
        _score: function(node, context) {
            var tokens = context.tokens;
            if (!tokens || !tokens.length) return 0;
            var best = 0;
            var names = nodeNames(node);
            for (var ni = 0; ni < names.length; ni++) {
                best = Math.max(best, this.stringScorer._score(names[ni], { tokens: tokens }));
            }
            return best;
        }
    };
}

function subtreeBestScore(node, leafScorer, ctx) {
    var best = leafScorer._score(node, ctx);
    var children = node.children || [];
    for (var ci = 0; ci < children.length; ci++) {
        best = Math.max(best, subtreeBestScore(children[ci], leafScorer, ctx));
    }
    return best;
}

function createPathScorer(leafScorer) {
    return {
        leafScorer: leafScorer,
        _score: function(path, context) {
            var tokens = context.tokens;
            var siblingCounts = context.siblingCounts;
            var subtreeScore = context.subtreeScore;
            if (!tokens || !tokens.length) return 0;
            var weightedSum = 0;
            var totalWeight = 0;
            for (var i = 0; i < path.length; i++) {
                var dist = path.length - 1 - i;
                var depthWeight = Math.pow(2, -dist);
                var widthWeight = 1 / Math.log2((siblingCounts[i] || 1) + 1);
                var weight = depthWeight * widthWeight;
                var ownScore = this.leafScorer._score(path[i], { tokens: tokens });
                var nodeScore = (i === path.length - 1 && subtreeScore !== undefined)
                    ? Math.max(ownScore, subtreeScore * 0.5)
                    : ownScore;
                weightedSum += weight * nodeScore;
                totalWeight += weight;
            }
            return totalWeight > 0 ? weightedSum / totalWeight : 0;
        }
    };
}

function createDefaultScorers() {
    var stringScorer = createBestOfScorer([
        createExactScorer(),
        createStartsWithScorer(),
        createContainsScorer(),
        createFuzzyScorer()
    ]);
    return createNodeScorer(stringScorer);
}

function createTokenizer(options) {
    var prefixes = options.prefixes || [];
    var splitPattern = options.splitPattern || /\s+/;
    var normalizeFn = options.normalizeFn || normalizeText;

    return {
        tokenize: function(query) {
            var raw = String(query || "");
            var trimmed = raw.trim();
            var prefix = "";
            for (var pi = 0; pi < prefixes.length; pi++) {
                if (prefixes[pi] && trimmed.startsWith(prefixes[pi])) {
                    prefix = prefixes[pi];
                    break;
                }
            }
            var body = prefix ? trimmed.slice(prefix.length) : trimmed;
            var cursorAtNewToken = /\s$/.test(raw);
            var trimmedBody = body.trim();
            var rawTokens = trimmedBody ? trimmedBody.split(splitPattern).filter(function(t) { return t.length > 0; }) : [];
            var tokens = [];
            for (var ri = 0; ri < rawTokens.length; ri += 1) {
                var expanded = tokenizeForMatch(rawTokens[ri]);
                for (var ei = 0; ei < expanded.length; ei += 1) {
                    if (tokens.indexOf(expanded[ei]) < 0)
                        tokens.push(expanded[ei]);
                }
            }

            return {
                raw: trimmed,
                prefix: prefix,
                tokens: tokens,
                cursorAtNewToken: cursorAtNewToken
            };
        }
    };
}

function createDefaultTokenizer(prefixes) {
    return createTokenizer({ prefixes: prefixes });
}

function queryForPath(prefix, path) {
    return prefix + path.map(function(node) { return node.title || node.id; }).join(" ");
}

function defaultAction(node) {
    return node.defaultAction || node.action || null;
}

function resultForNode(node, prefix, path, kind, score, tokens, leafScorer, tokenScores) {
    var action = defaultAction(node);
    var fullPath = path.concat([node]);
    var hasChildren = (node.children || []).length > 0;
    var isContainer = !action && hasChildren;
    var completionText = isContainer
        ? (prefix ? prefix + " " : queryForPath(prefix, fullPath) + " ")
        : (prefix ? prefix + " " : "") + (node.title || node.id);

    var replaceText = (action && action.replaceQuery) ? action.replaceQuery : completionText;
    var onComplete = (action && typeof action.onComplete === 'function') ? action.onComplete
        : (typeof node.onComplete === 'function') ? node.onComplete
        : null;
    var breadcrumbs = path.map(function(item) { return item.title || item.id; });
    var children = (node.children || []).map(function(child) {
        var childAction = defaultAction(child);
        var childScore = leafScorer && tokens && tokens.length > 0
            ? leafScorer._score(child, { tokens: tokens })
            : 1;
        return {
            id: node.id + ":" + (child.id || ""),
            title: child.title || child.id,
            subtitle: child.subtitle || null,
            icon: child.icon || node.icon || null,
            relevance: childScore,
            actions: childAction ? [{ id: "run", label: "Run", icon: "system-run", default: true }] : [],
            metadata: { action: childAction }
        };
    });

    return {
        id: prefix + ":" + fullPath.map(function(item) { return item.id; }).join(":"),
        title: node.title || node.id,
        subtitle: node.subtitle || null,
        breadcrumbs: breadcrumbs,
        icon: node.icon || null,
        relevance: score,
        dangerous: !!node.dangerous,
        executable: kind !== "completion" && !!action,
        expandable: hasChildren,
        children: children,
        completionText: completionText,
        replaceText: replaceText,
        enter: action && action.replaceQuery
            ? { type: "replace-query", text: action.replaceQuery }
            : kind === "completion"
                ? { type: "replace-query", text: completionText }
                : { type: "activate", action: action },
        shiftEnter: { type: "replace-query", text: completionText },
        actions: [
            { id: kind === "completion" ? "complete" : "run", label: kind === "completion" ? "Complete" : "Run", icon: kind === "completion" ? "go-next" : "system-run", default: true }
        ],
        onComplete: onComplete,
        tokenScores: tokenScores || null,
        metadata: {
            kind: kind,
            replaceQuery: kind === "completion" ? completionText : null,
            commandPath: fullPath.map(function(item) { return item.id; }),
            action: action
        }
    };
}

function collectMatches(nodes, tokens, currentPath, results, siblingCounts, leafScorer, pathScorer, ctx, inheritedScores) {
    for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        var newPath = currentPath.concat([node]);
        var newSiblings = siblingCounts.concat([nodes.length]);

        var ownScores = computeOwnTokenScores(node, tokens);
        var effectiveScores = combineTokenScores(inheritedScores, ownScores);

        var nodeScore = leafScorer._score(node, { tokens: tokens });
        var subtreeScore = subtreeBestScore(node, leafScorer, { tokens: tokens });
        var matchScore = pathScorer._score(newPath, { tokens: tokens, siblingCounts: newSiblings, subtreeScore: subtreeScore });

        var hasAction = !!defaultAction(node);
        var hasChildren = (node.children || []).length > 0;
        var isContainer = !hasAction && hasChildren;
        var showAsResult = node.result !== false && matchScore > 0 && !isContainer;

        if (showAsResult) {
            results.push({
                node: node,
                path: newPath,
                parentPath: currentPath,
                depth: newPath.length,
                score: matchScore,
                nodeScore: nodeScore,
                kind: hasAction ? "action" : "completion",
                isContainer: false,
                tokenScores: effectiveScores
            });
        }

        if (isContainer && matchScore > 0 && node.result !== false) {
            results.push({
                node: node,
                path: newPath,
                parentPath: currentPath,
                depth: newPath.length,
                score: matchScore,
                nodeScore: nodeScore,
                kind: "container",
                isContainer: true,
                tokenScores: effectiveScores
            });
        }

        if (node.children && node.children.length > 0) {
            collectMatches(node.children, tokens, newPath, results, newSiblings, leafScorer, pathScorer, ctx, effectiveScores);
        }
    }
}

function findBestLeafPath(allMatches) {
    var bestLeaf = null;
    for (var i = 0; i < allMatches.length; i++) {
        var m = allMatches[i];
        var hasChildren = (m.node.children || []).length > 0;
        if (!hasChildren || m.nodeScore > 0) {
            if (!bestLeaf || m.score > bestLeaf.score || (m.score === bestLeaf.score && m.depth > bestLeaf.depth)) {
                bestLeaf = m;
            }
        }
    }
    return bestLeaf;
}

function buildSiblingThreshold(allMatches, bestLeaf) {
    if (!bestLeaf || bestLeaf.path.length < 2) return 0;
    var parentPath = bestLeaf.parentPath;
    var bestNodeScore = bestLeaf.nodeScore;
    var siblingMatches = allMatches.filter(function(m) {
        if (m.path.length !== bestLeaf.path.length) return false;
        for (var i = 0; i < parentPath.length; i++) {
            if ((m.path[i].id || m.path[i].title) !== (parentPath[i].id || parentPath[i].title)) return false;
        }
        return true;
    });
    var scores = siblingMatches.map(function(m) { return m.nodeScore; });
    scores.push(bestNodeScore);
    var maxSiblingScore = Math.max.apply(null, scores);
    return Math.max(maxSiblingScore * 0.5, 0.15);
}

function suggest(query, prefixes, roots, leafScorer, tokenizer) {
    var scorer = leafScorer || createDefaultScorers();
    var tok = tokenizer || createDefaultTokenizer(prefixes);
    var parsed = tok.tokenize(query);
    if (!prefixes || prefixes.length === 0)
        return [];

    var tokens = parsed.tokens.filter(function(t) { return t.length > 0; });
    var pathScorer = createPathScorer(scorer);
    var ctx = { tokens: tokens };

    if (!tokens.length) {
        return (roots || []).filter(function(node) { return node.result !== false; }).map(function(node) { return resultForNode(node, parsed.prefix, [], "completion", 1, tokens, scorer, null); });
    }

    var allMatches = [];
    collectMatches(roots, tokens, [], allMatches, [], scorer, pathScorer, ctx);

    if (allMatches.length === 0)
        return [];

    allMatches.sort(function(a, b) { return b.score - a.score || a.depth - b.depth; });
    var bestMatch = allMatches[0];
    ctx.bestMatchDepth = bestMatch.depth;

    if (parsed.cursorAtNewToken) {
        return (bestMatch.node.children || []).map(function(node) {
            return resultForNode(node, parsed.prefix, bestMatch.path, "completion", 1, tokens, scorer, bestMatch.tokenScores);
        });
    }

    var bestLeaf = findBestLeafPath(allMatches);
    var siblingThreshold = buildSiblingThreshold(allMatches, bestLeaf);
    ctx.bestMatchDepth = bestLeaf ? bestLeaf.depth : bestMatch.depth;

    var penaltyScorer = createPenaltyScorer(
        { _score: function(_, c) { return c.rawScore; } },
        function(c) {
            var d = c.depth - c.bestMatchDepth;
            return d >= 0 ? Math.pow(2, -d) : Math.pow(2, 2 * d);
        }
    );

    var scored = [];
    for (var mi = 0; mi < allMatches.length; mi++) {
        var m = allMatches[mi];

        var finalScore = penaltyScorer._score(null, {
            depth: m.depth,
            rawScore: m.score,
            bestMatchDepth: ctx.bestMatchDepth
        });
        if (finalScore <= 0.01) continue;

        if (m.isContainer) {
            if (m.node.result !== false) {
                scored.push(resultForNode(m.node, parsed.prefix, m.parentPath, "completion", finalScore, tokens, scorer, m.tokenScores));
            }
            continue;
        }

        var hasAction = !!defaultAction(m.node);
        if (!hasAction && siblingThreshold > 0 && m.nodeScore < siblingThreshold) {
            var hasChildren = (m.node.children || []).length > 0;
            if (!hasChildren || m.nodeScore < siblingThreshold * 0.5) continue;
        }

        var finalScore = penaltyScorer._score(null, {
            depth: m.depth,
            rawScore: m.score,
            bestMatchDepth: ctx.bestMatchDepth
        });
        if (finalScore > 0.01) {
            scored.push(resultForNode(m.node, parsed.prefix, m.parentPath, m.kind, finalScore, tokens, scorer, m.tokenScores));
        }
    }

    return scored.sort(function(a, b) { return b.relevance - a.relevance || a.title.localeCompare(b.title); });
}
