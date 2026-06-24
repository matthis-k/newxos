import QtQml

QtObject {
    id: root

    property var defaultEvaluationProfile: ({
        mode: "generic+custom",
        strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
        scorePolicy: "default",
        profile: {
            evidence: [["field-match", { filterType: "all" }], "switch-action", "semantic", "token-claim", "usage", "recency"],
            boost: ["descendant-boost"],
            childVisible: ["visible-flag"],
            tokenFlow: ["pass-all"],
            takeoverRequest: [],
            takeoverAccept: [],
            expand: [],
            retainParent: [],
            defaultAction: ["default-action-owner"],
            riskGate: ["risk-gate"],

        }
    })

    property var backendEvaluationProfile: ({
        mode: "generic",
        strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"],
        scorePolicy: "backend",
        profile: {
            evidence: [["field-match", { filterType: "all" }], "switch-action", "semantic", "usage", "recency"],
            boost: ["descendant-boost"],
            childVisible: ["visible-flag", ["above-min-score", { threshold: 0.25 }]],
            tokenFlow: ["pass-all"],
            takeoverRequest: [],
            takeoverAccept: [],
            expand: [],
            retainParent: [],
            defaultAction: ["default-action-owner"],
            riskGate: ["risk-gate"]
        }
    })

    property var switchProfile: ({
        mode: "generic+custom",
        strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"],
        scorePolicy: "default",
        profile: {
            evidence: [["field-match", { filterType: "primary" }], ["field-match", { filterType: "breadcrumb" }], "switch-action"],
            boost: ["descendant-boost", "switch-aliases"],
            childVisible: ["has-own-score"],
            tokenFlow: ["consume-switch-pass-rest"],
            takeoverRequest: [],
            takeoverAccept: [],
            expand: ["expand-on-own-match-or-trailing-space"],
            retainParent: [],
            defaultAction: ["default-action-owner"],
            riskGate: ["risk-gate"]
        }
    })

    property var defaultPriority: 0

    function groupProfile(options) {
        var opts = options || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                evidence: opts.evidence || [["field-match", { filterType: "all" }], "switch-action", "semantic", "token-claim", "usage", "recency"],
                boost: opts.boost || ["descendant-boost"],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["consume-namespace-pass-rest"],
                takeoverRequest: opts.takeoverRequest || [
                    "child-own-match-parent-no-own-match",
                    "explicit-child-token",
                    "child-covers-passed-tokens",
                    "own-score-dominates-takeover"
                ],
                takeoverAccept: opts.takeoverAccept || ["accept-dominated-claims"],
                expand: opts.expand || ["expand-on-own-match-or-trailing-space"],
                retainParent: opts.retainParent || [{ name: "retain-parent-when", args: { condition: "own-match" } }],
                defaultAction: opts.defaultAction || ["default-action-expand"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    function leafProfile(options) {
        var opts = options || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                evidence: opts.evidence || [["field-match", { filterType: "all" }], "semantic", "token-claim", "usage", "recency"],
                boost: opts.boost || [],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["pass-all"],
                takeoverRequest: [],
                takeoverAccept: [],
                expand: [],
                retainParent: [],
                defaultAction: opts.defaultAction || ["default-action-owner"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    function isGroupTemplate(node) {
        return node && (node.template === "action-group" || node.template === "flat-action-group" || node.template === "switch");
    }

    function behaviorForNode(node, children, extra) {
        if (node.behavior)
            return Object.assign({}, extra || {}, node.behavior);
        return extra || {};
    }

    function defaultAction(node) {
        return node.defaultAction || node.action || null;
    }
}
