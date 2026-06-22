import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    property string policyId
    property string filterType: "all"
    property var strategyList: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"]

    function policyMatch(node, query, ctx, specArgs) {
        if (query.isEmpty)
            return [];
        var effectiveFilterType = specArgs && specArgs.filterType !== undefined
            ? String(specArgs.filterType)
            : filterType;
        var originGroup = effectiveFilterType === "breadcrumb" ? "inherited" : "own";
        var fields = IndexBuilder.searchableFields(node);
        var filtered = Evidence.filterFields(fields, effectiveFilterType);
        var out = [];
        for (var fi = 0; fi < filtered.length; fi += 1) {
            var matches = Evidence.matchField(filtered[fi], query, strategyList);
            for (var mi = 0; mi < matches.length; mi += 1)
                matches[mi].originGroup = originGroup;
            out = out.concat(matches);
        }
        return out;
    }

    Component.onCompleted: {
        var group = filterType === "breadcrumb" ? "inherited" : "own";
        Launcher.PolicyRegistry.registerEvidence(policyId, group, policyMatch);
    }
}
