pragma Singleton
import QtQml
import Quickshell
import "PolicyChain.qml"
import "CompositeSearchPolicyRegistry.js" as JsRegistry

Singleton {
    function evaluateTakeoverRequests(parentEv, childEvs, ctx) {
        var claims = [];
        if (!childEvs || !childEvs.length) return claims;

        for (var ci = 0; ci < childEvs.length; ci += 1) {
            var child = childEvs[ci];
            if (!child.visible && !child.candidate) continue;
            var childClaims = emitClaims(child, parentEv, ctx);
            claims = claims.concat(childClaims);
        }

        claims.sort(function(a, b) { return b.strength - a.strength; });
        return claims;
    }

    function emitClaims(childEv, parentEv, ctx) {
        var claims = [];
        var child = childEv.node;
        var parent = parentEv.node;
        if (!child || !parent) return claims;

        var profile = (parentEv.node.evaluationProfile && parentEv.node.evaluationProfile.profile) || {};
        var takeoverNames = profile.takeoverRequest || [];

        if (takeoverNames.length === 0) {
            takeoverNames = ["explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"];
        }

        PolicyChain.run(takeoverNames, function(name, spec) {
            var policy = PolicyChain.lookupPolicy(JsRegistry.takeoverRequest, spec);
            if (!policy) return null;
            var result = policy.apply(childEv, parentEv, ctx, spec && spec.args);
            if (result && Array.isArray(result)) {
                claims = claims.concat(result);
                return result.length > 0 ? true : null;
            }
            if (result && result.claimantId) {
                claims.push(result);
                return result;
            }
            return null;
        }, "accumulate");

        return claims;
    }

    function decideTakeover(parentEv, claims, ctx) {
        if (!claims || !claims.length) {
            return {
                accepted: false,
                ownerId: parentEv.node ? parentEv.node.id : "",
                representation: "keep-parent",
                retainParent: true,
                suppressParentActions: false,
                selectedOwnerId: parentEv.node ? parentEv.node.id : "",
                defaultActionOwnerId: parentEv.node ? parentEv.node.id : "",
                activation: "normal",
                reason: "no takeover claims"
            };
        }

        var profile = (parentEv.node.evaluationProfile && parentEv.node.evaluationProfile.profile) || {};
        var acceptNames = profile.takeoverAccept || ["accept-dominated-claims"];
        var acceptResult = PolicyChain.run(acceptNames, function(name, spec) {
            var policy = PolicyChain.lookupPolicy(JsRegistry.takeoverAccept, spec);
            if (!policy) return null;
            return policy.apply(parentEv, claims, ctx, spec && spec.args);
        }, "first-wins");

        var accepted = acceptResult.value;
        if (!accepted || !accepted.accepted) {
            return {
                accepted: false,
                ownerId: parentEv.node ? parentEv.node.id : "",
                representation: "keep-parent",
                retainParent: true,
                suppressParentActions: false,
                selectedOwnerId: parentEv.node ? parentEv.node.id : "",
                defaultActionOwnerId: parentEv.node ? parentEv.node.id : "",
                activation: "normal",
                reason: accepted ? accepted.reason : "no accept policy matched"
            };
        }

        return accepted;
    }

    function defaultAcceptPolicy(parentEv, claims, ctx) {
        if (!claims || !claims.length) {
            return { accepted: false, reason: "no claims" };
        }

        var bestClaim = claims[0];
        var scoreDominance = false;

        if (bestClaim.claimantId && bestClaim.targetId === parentEv.node.id) {
            var claimantEv = findChildEv(parentEv, bestClaim.claimantId);
            if (claimantEv && claimantEv.score && parentEv.score) {
                scoreDominance = claimantEv.score > parentEv.score + 0.15;
            }
        }

        var selectedOwnerId = bestClaim.claimantId || parentEv.node.id;
        var defaultActionOwnerId = parentEv.node.id;
        var suppressParentActions = false;
        var retainParent = true;
        var representation = "keep-parent";
        var activation = "normal";
        var reason = "";

        var dominanceClaim = claims.filter(function(c) { return c.kind === "selection" || c.kind === "defaultAction"; });
        if (dominanceClaim.length > 0) {
            var dc = dominanceClaim[0];
            selectedOwnerId = dc.claimantId;
            if (dc.kind === "defaultAction" || (dc.kind === "selection" && scoreDominance)) {
                defaultActionOwnerId = dc.claimantId;
                retainParent = false;
                representation = "promote-child";
                suppressParentActions = true;
                reason = "child " + (dc.claimantId || "") + " dominates via " + dc.reason;
            } else {
                reason = "child " + (dc.claimantId || "") + " claims " + (dc.kind || "selection") + " via " + dc.reason;
            }
        } else {
            reason = "no dominant claim, keeping parent";
        }

        if (parentEv.node && (parentEv.node.risk || parentEv.node.dangerous)) {
            activation = "confirm";
            reason += " (parent risk requires confirmation)";
        }

        return {
            accepted: true,
            ownerId: selectedOwnerId,
            representation: representation,
            retainParent: retainParent,
            suppressParentActions: suppressParentActions,
            selectedOwnerId: selectedOwnerId,
            defaultActionOwnerId: defaultActionOwnerId,
            activation: activation,
            reason: reason
        };
    }

    function findChildEv(parentEv, childId) {
        if (!parentEv || !parentEv.children) return null;
        for (var i = 0; i < parentEv.children.length; i += 1) {
            if (parentEv.children[i].node && parentEv.children[i].node.id === childId)
                return parentEv.children[i];
        }
        return null;
    }

    function explicitChildToken(childEv, parentEv, ctx, args) {
        var claims = [];
        if (!childEv.visible || !childEv.ownScore) return claims;
        var tokens = ctx.query && ctx.query.tokens || [];

        if (tokens.length === 0) return claims;

        var childCovered = {};
        var evidence = childEv.ownEvidence || childEv.evidence || [];
        for (var ei = 0; ei < evidence.length; ei += 1) {
            var e = evidence[ei];
            if (e.tokenIndex !== undefined) childCovered[e.tokenIndex] = true;
        }

        var parentCovered = {};
        var parentEvidence = parentEv.ownEvidence || parentEv.evidence || [];
        for (var pi = 0; pi < parentEvidence.length; pi += 1) {
            var pe = parentEvidence[pi];
            if (pe.tokenIndex !== undefined) parentCovered[pe.tokenIndex] = true;
        }

        var uniqueTokens = 0;
        for (var ti = 0; ti < tokens.length; ti += 1) {
            if (childCovered[ti] && !parentCovered[ti]) uniqueTokens += 1;
        }

        if (uniqueTokens > 0) {
            claims.push({
                claimantId: childEv.node.id,
                targetId: parentEv.node.id,
                kind: "selection",
                strength: 0.6 + (uniqueTokens / tokens.length) * 0.3,
                reason: "explicit-child-token: child covers " + uniqueTokens + " unique tokens",
                evidence: [{ field: "token-coverage", value: uniqueTokens / tokens.length }]
            });
        }

        return claims;
    }

    function childCoversPassedTokens(childEv, parentEv, ctx, args) {
        var claims = [];
        var tokenFlow = parentEv.tokenFlow;
        if (!tokenFlow || !tokenFlow.passed || tokenFlow.passed.length === 0) return claims;

        var passedTexts = tokenFlow.passed.map(function(t) { return t.normalized; });
        var childEvidence = childEv.ownEvidence || childEv.evidence || [];
        var coveredTokens = 0;

        for (var ei = 0; ei < childEvidence.length; ei += 1) {
            var e = childEvidence[ei];
            if (e.tokenIndex !== undefined && e.tokenIndex < passedTexts.length) {
                coveredTokens += 1;
            }
        }

        if (coveredTokens > 0) {
            claims.push({
                claimantId: childEv.node.id,
                targetId: parentEv.node.id,
                kind: "defaultAction",
                strength: 0.5 + (coveredTokens / passedTexts.length) * 0.3,
                reason: "child-covers-passed-tokens: covers " + coveredTokens + " of " + passedTexts.length + " passed tokens",
                evidence: [{ field: "passed-token-coverage", value: coveredTokens / passedTexts.length }]
            });
        }

        return claims;
    }

    function ownScoreDominatesTakeover(childEv, parentEv, ctx, args) {
        var claims = [];
        var margin = (args && args.margin) || 0.18;
        if (!childEv.ownScore || !parentEv.ownScore) return claims;
        if (childEv.ownScore >= parentEv.ownScore + margin) {
            claims.push({
                claimantId: childEv.node.id,
                targetId: parentEv.node.id,
                kind: "selection",
                strength: 0.7,
                reason: "own-score-dominates: child score " + childEv.ownScore.toFixed(3) + " beats parent " + parentEv.ownScore.toFixed(3) + " by " + margin,
                evidence: [{ field: "score-margin", value: childEv.ownScore - parentEv.ownScore }]
            });
        }
        return claims;
    }

    function exactActionTokenTakeover(childEv, parentEv, ctx, args) {
        var claims = [];
        if (!childEv.node || !childEv.node.switchActions) return claims;
        var tokens = ctx.query && ctx.query.tokens || [];
        if (tokens.length === 0) return claims;

        var lastToken = tokens[tokens.length - 1];
        var actionLabels = ["on", "off", "toggle", "enable", "disable", "connect", "disconnect"];
        if (actionLabels.indexOf(lastToken.normalized) < 0) return claims;

        claims.push({
            claimantId: childEv.node.id,
            targetId: parentEv.node.id,
            kind: "defaultAction",
            strength: 0.85,
            reason: "exact-action-token: last token '" + lastToken.raw + "' matches switch action alias",
            evidence: [{ field: "action-token-match", value: 1.0 }]
        });

        return claims;
    }
}
