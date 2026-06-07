import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    property string policyId
    property string filterType: "all"
    property var strategyList: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"]

    function policyMatch(node, query, ctx) {
        if (query.isEmpty)
            return [];
        var fields = IndexBuilder.searchableFields(node);
        var filtered = Evidence.filterFields(fields, filterType);
        var out = [];
        for (var fi = 0; fi < filtered.length; fi += 1)
            out = out.concat(Evidence.matchField(filtered[fi], query, strategyList));
        return out;
    }

    Component.onCompleted: {
        var group = filterType === "breadcrumb" ? "inherited" : "own";
        Launcher.PolicyRegistry.registerEvidence(policyId, group, policyMatch);
    }
}
