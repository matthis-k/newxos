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

        var ownEv = evaluated.ownEvidence || [];
        var directTokens = {};
        for (var ei = 0; ei < ownEv.length; ei += 1) {
            var covered = Evidence.inferCoveredTokenIndexes(ownEv[ei], query);
            for (var ci = 0; ci < covered.length; ci += 1) {
                if (typeof covered[ci] === "number")
                    directTokens[covered[ci]] = true;
            }
        }

        var filtered;
        if (Object.keys(directTokens).length === 0) {
            filtered = inherited;
        } else {
            filtered = [];
            for (var fi = 0; fi < inherited.length; fi += 1) {
                var e = inherited[fi];
                var covered = Evidence.inferCoveredTokenIndexes(e, query);
                var hasDirect = false;
                for (var ci = 0; ci < covered.length; ci += 1) {
                    if (typeof covered[ci] === "number" && directTokens[covered[ci]]) {
                        hasDirect = true;
                        break;
                    }
                }
                if (!hasDirect) filtered.push(e);
            }
        }

        if (!filtered.length)
            return;

        var mapped = [];
        for (var mi = 0; mi < filtered.length; mi += 1) {
            var fe = filtered[mi];
            mapped.push(Object.assign({}, fe, { kind: "path-" + fe.kind, originKind: "ancestor", depth: -1, weight: fe.weight * 0.7, effective: fe.score * fe.weight * 0.7 }));
        }

        var addedInherited = evaluated.inheritedEvidence || [];
        evaluated.inheritedEvidence = addedInherited.concat(mapped);
        evaluated.evidence = ownEv.concat(evaluated.inheritedEvidence);

        var inheritedResult = Evidence.scoreEvidence(evaluated.inheritedEvidence, evaluated.node, ctx);
        evaluated.inheritedScore = Tokenize.clamp(Math.max(evaluated.inheritedScore || 0, inheritedResult.value));
        evaluated.score = Tokenize.clamp(Math.max(evaluated.ownScore || 0, evaluated.inheritedScore, evaluated.descendantScore || 0));
        evaluated.visible = evaluated.visible || inheritedResult.visible;
    }

    function pathEvidenceFromAncestorsInner(node, query, ctx) {
        if (!ctx.includePath || query.isEmpty)
            return [];
        var chain = Evaluate.collectParentChain(node);
        var chainLen = chain.length;
        if (chainLen <= 1) return [];
        var out = [];
        var weight = 0.24;
        for (var i = 0; i < chainLen - 1; i += 1) {
            var ancestor = chain[i];
            var fields = IndexBuilder.searchableFields(ancestor);
            for (var fi = 0; fi < fields.length; fi += 1) {
                var f = fields[fi];
                if (f.field !== "label" && f.field !== "aliases" && f.field !== "keywords") continue;
                var inherited = Object.assign({}, f, { field: "ancestor-" + f.field, weight: weight * Math.min(1, f.weight) });
                out = out.concat(Evidence.matchField(inherited, query, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"]));
            }
            weight *= 0.72;
        }
        return out;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerInherit("path-evidence", policyApply);
    }
}
