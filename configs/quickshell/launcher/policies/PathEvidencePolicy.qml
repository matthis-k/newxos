import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    function policyApply(evaluated, query, ctx) {
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

        var inheritedResult = Evidence.scoreEvidence(addedInherited, evaluated.node, ctx);
        evaluated.inheritedScore = Tokenize.clamp(Math.max(evaluated.inheritedScore || 0, inheritedResult.value));
        evaluated.score = Tokenize.clamp(Math.max(evaluated.ownScore || 0, evaluated.inheritedScore, evaluated.descendantScore || 0));
        evaluated.visible = evaluated.visible || inheritedResult.visible;
    }

    function pathEvidenceFromAncestorsInner(node, query, ctx) {
        if (!ctx.includePath || query.isEmpty)
            return [];
        var chain = collectParentChain(node).slice(0, -1);
        var out = [];
        var weight = 0.24;
        for (var i = 0; i < chain.length; i += 1) {
            var fields = IndexBuilder.searchableFields(chain[i]).filter(function(f) {
                return ["label", "aliases", "keywords"].indexOf(f.field) >= 0;
            });
            for (var fi = 0; fi < fields.length; fi += 1) {
                var inherited = Object.assign({}, fields[fi], { field: "ancestor-" + fields[fi].field, weight: weight * Math.min(1, fields[fi].weight) });
                out = out.concat(Evidence.matchField(inherited, query, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"]));
            }
            weight *= 0.72;
        }
        return out;
    }

    function collectParentChain(node) {
        var chain = [];
        var cur = node;
        while (cur && cur.kind !== "root") {
            chain.unshift(cur);
            cur = cur.parent;
        }
        return chain;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerInherit("path-evidence", policyApply);
    }
}
