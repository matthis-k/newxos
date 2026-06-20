import QtQml

QtObject {
    id: root

    property var defaultEvaluationProfile: ({
        mode: "generic+custom",
        strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
        scorePolicy: "default",
        profile: {
            evidence: ["field-match:all", "switch-action", "semantic", "token-claim", "usage", "recency"],
            inherit: ["path-evidence"],
            boost: ["descendant-boost"],
            childVisible: ["visible-flag"],
            childBypass: ["own-score-beats-parent", "score-dominates:0.03"],
            tokenFlow: ["pass-all"],
            takeoverRequest: ["explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
            takeoverAccept: ["accept-dominated-claims"],
            expand: ["expand-when"],
            retainParent: ["retain-always"],
            defaultAction: ["default-action-owner"],
            riskGate: ["risk-gate"]
        }
    })

    property var backendEvaluationProfile: ({
        mode: "generic",
        strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"],
        scorePolicy: "backend",
        profile: {
            evidence: ["field-match:all", "switch-action", "semantic", "usage", "recency"],
            inherit: ["path-evidence"],
            boost: ["descendant-boost"],
            childVisible: ["visible-flag", "above-min-score:0.25"],
            childBypass: ["own-score-beats-parent", "score-dominates:0.03"],
            tokenFlow: ["pass-all"],
            takeoverRequest: ["explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
            takeoverAccept: ["accept-dominated-claims"],
            expand: ["expand-when"],
            retainParent: ["retain-always"],
            defaultAction: ["default-action-owner"],
            riskGate: ["risk-gate"]
        }
    })

    property var switchProfile: ({
        mode: "generic+custom",
        strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"],
        scorePolicy: "default",
        profile: {
            evidence: ["field-match:primary", "field-match:breadcrumb", "switch-action"],
            inherit: [],
            boost: ["descendant-boost", "switch-aliases"],
            childVisible: ["has-own-score"],
            childBypass: ["score-dominates:0.03"],
            tokenFlow: ["pass-all"],
            takeoverRequest: ["explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
            takeoverAccept: ["accept-dominated-claims"],
            expand: ["expand-when"],
            retainParent: ["retain-always"],
            defaultAction: ["default-action-owner"],
            riskGate: ["risk-gate"]
        }
    })

    function defaultFlattenPolicy(priority) {
        return {
            modeHint: "group-dominance",
            priority: priority || 0,
            groupDisplay: {
                parentWinsMargin: 0.08,
                childWinsMargin: 0.03,
                childDominatesMargin: 0.18,
                maxFlattenedChildren: 3,
                minChildScore: 0.25,
                showGroupHeaderInFilteredMode: true,
                showAllChildrenOnParentMatch: true,
                parentMatchMinScore: 0.15
            }
        };
    }

    property int defaultPriority: 0

    function categoryGroupBehavior(options) {
        var opts = options || {};
        return {
            flattenPolicy: {
                modeHint: "group-dominance",
                priority: opts.priority === undefined ? root.defaultPriority : opts.priority,
                groupDisplay: {
                    parentWinsMargin: opts.parentWinsMargin === undefined ? 0.08 : opts.parentWinsMargin,
                    childWinsMargin: opts.childWinsMargin === undefined ? 0.03 : opts.childWinsMargin,
                    childDominatesMargin: opts.childDominatesMargin === undefined ? 0.18 : opts.childDominatesMargin,
                    maxFlattenedChildren: opts.maxFlattenedChildren === undefined ? 3 : opts.maxFlattenedChildren,
                    minChildScore: opts.minChildScore === undefined ? 0.25 : opts.minChildScore,
                    showGroupHeaderInFilteredMode: opts.showGroupHeaderInFilteredMode === undefined ? true : opts.showGroupHeaderInFilteredMode,
                    showAllChildrenOnParentMatch: opts.showAllChildrenOnParentMatch === undefined ? true : opts.showAllChildrenOnParentMatch,
                    flattenAllChildrenOnParentMatch: !!opts.flattenAllChildrenOnParentMatch,
                    parentMatchMinScore: opts.parentMatchMinScore === undefined ? 0.25 : opts.parentMatchMinScore,
                    maxNestedChildren: opts.maxNestedChildren
                }
            },
            displayPolicy: opts.displayPolicy || (opts.breadcrumbMode ? { breadcrumbMode: opts.breadcrumbMode } : null)
        };
    }

    function behaviorForNode(node, children, extra) {
        if (node.template === "action-group" || node.template === "flat-action-group" || node.template === "switch")
            extra = root.categoryGroupBehavior(node.groupOptions || {});
        if (node.behavior)
            return Object.assign({}, extra, node.behavior);
        return extra;
    }

    function defaultAction(node) {
        return node.defaultAction || node.action || null;
    }
}
