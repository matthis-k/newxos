// Centralized evaluation profile factories.
// Reduces duplicate inline profile objects in backend files.
// Backends import this instead of defining their own profile functions.
// JS module — no QML type registration, no circular dependency.

function _defaultArr(arr, fallback) { return arr !== undefined ? arr : fallback; }

function groupProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic+custom",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"]),
        scorePolicy: opts.scorePolicy || "default",
        profile: {
            fields: _defaultArr(opts.fields, ["label", "aliases"]),
            evidence: _defaultArr(opts.evidence, ["field-match", "switch-action", "semantic"]),
            boost: _defaultArr(opts.boost, ["descendant-boost"]),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag"]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["consume-namespace-pass-rest"]),
            takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : ["child-own-match-parent-no-own-match", "explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
            takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : ["accept-dominated-claims"],
            expand: _defaultArr(opts.expand, ["expand-on-own-match-or-trailing-space"]),
            retainParent: _defaultArr(opts.retainParent, [{ name: "retain-parent-when", args: { condition: "own-match" } }]),
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-expand"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}

function switchProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic+custom",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"]),
        scorePolicy: opts.scorePolicy || "default",
        profile: {
            fields: _defaultArr(opts.fields, ["label", "aliases"]),
            evidence: _defaultArr(opts.evidence, ["field-match", ["field-match", { fields: ["breadcrumb"] }], "switch-action"]),
            boost: _defaultArr(opts.boost, ["descendant-boost", "switch-aliases"]),
            childVisible: _defaultArr(opts.childVisible, ["has-own-score"]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["consume-switch-pass-rest"]),
            takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : [],
            takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : [],
            expand: _defaultArr(opts.expand, ["expand-on-own-match-or-trailing-space"]),
            retainParent: _defaultArr(opts.retainParent, ["retain-always"]),
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-owner"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}

function appProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic+custom",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"]),
        scorePolicy: opts.scorePolicy || "default",
        profile: {
            fields: _defaultArr(opts.fields, ["label"]),
            evidence: _defaultArr(opts.evidence, [["field-match", { fields: ["label"] }], "semantic", "usage", "recency"]),
            boost: _defaultArr(opts.boost, ["descendant-boost"]),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag"]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["consume-own-pass-rest"]),
            takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : ["child-own-match-parent-no-own-match", "explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
            takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : ["accept-dominated-claims"],
            expand: _defaultArr(opts.expand, ["expand-on-trailing-space"]),
            retainParent: _defaultArr(opts.retainParent, [{ name: "retain-parent-when", args: { condition: "own-match" } }]),
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-owner"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}

function visualRootProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic+custom",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"]),
        scorePolicy: opts.scorePolicy || "default",
        profile: {
            fields: _defaultArr(opts.fields, ["label"]),
            evidence: _defaultArr(opts.evidence, [["field-match", { fields: ["label"] }], "semantic"]),
            boost: _defaultArr(opts.boost, ["descendant-boost"]),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag"]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["pass-all"]),
            takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : ["child-own-match-parent-no-own-match", "explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
            takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : ["accept-dominated-claims"],
            expand: _defaultArr(opts.expand, ["expand-on-own-match-or-trailing-space"]),
            retainParent: _defaultArr(opts.retainParent, [{ name: "retain-parent-when", args: { condition: "own-match" } }]),
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-expand"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}

function backendRootProfile(opts) {
    opts = opts || {};
    return {
        mode: opts.mode || "generic",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"]),
        scorePolicy: opts.scorePolicy || "backend",
        profile: {
            fields: _defaultArr(opts.fields, ["label", "aliases"]),
            evidence: _defaultArr(opts.evidence, ["field-match"]),
            boost: _defaultArr(opts.boost, []),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag"]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["pass-all"]),
            takeoverRequest: opts.takeoverRequest || [],
            takeoverAccept: opts.takeoverAccept || [],
            expand: opts.expand || [],
            retainParent: opts.retainParent || [],
            defaultAction: opts.defaultAction || [],
            riskGate: opts.riskGate || []
        }
    };
}

function defaultNodeProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic+custom",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"]),
        scorePolicy: opts.scorePolicy || "default",
        profile: {
            fields: _defaultArr(opts.fields, ["label", "aliases"]),
            evidence: _defaultArr(opts.evidence, ["field-match", "switch-action", "semantic", "token-claim", "usage", "recency"]),
            boost: _defaultArr(opts.boost, ["descendant-boost"]),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag"]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["pass-all"]),
            takeoverRequest: opts.takeoverRequest || [],
            takeoverAccept: opts.takeoverAccept || [],
            expand: opts.expand || [],
            retainParent: opts.retainParent || [],
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-owner"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}

function leafProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic+custom",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"]),
        scorePolicy: opts.scorePolicy || "default",
        profile: {
            fields: _defaultArr(opts.fields, ["label", "aliases"]),
            evidence: _defaultArr(opts.evidence, ["field-match", "semantic", "token-claim", "usage", "recency"]),
            boost: _defaultArr(opts.boost, []),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag"]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["pass-all"]),
            takeoverRequest: opts.takeoverRequest || [],
            takeoverAccept: opts.takeoverAccept || [],
            expand: opts.expand || [],
            retainParent: opts.retainParent || [],
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-owner"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}

function calculatorProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic+custom",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym", "semantic"]),
        scorePolicy: opts.scorePolicy || "semantic-result",
        profile: {
            fields: _defaultArr(opts.fields, ["label", "aliases"]),
            evidence: _defaultArr(opts.evidence, ["field-match", "semantic"]),
            boost: _defaultArr(opts.boost, []),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag", ["above-min-score", { threshold: 0.25 }]]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["pass-all"]),
            takeoverRequest: opts.takeoverRequest || [],
            takeoverAccept: opts.takeoverAccept || [],
            expand: _defaultArr(opts.expand, ["expand-none"]),
            retainParent: _defaultArr(opts.retainParent, ["retain-always"]),
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-owner"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}

function fileProfile(opts) {
    opts = opts || {};
    return {
        mode: "generic",
        strategies: _defaultArr(opts.strategies, ["exact", "prefix", "compact", "substring", "acronym"]),
        scorePolicy: opts.scorePolicy || "backend",
        profile: {
            fields: _defaultArr(opts.fields, ["label", "aliases", "path"]),
            evidence: _defaultArr(opts.evidence, ["field-match", "usage", "recency"]),
            boost: _defaultArr(opts.boost, ["descendant-boost"]),
            childVisible: _defaultArr(opts.childVisible, ["visible-flag", ["above-min-score", { threshold: 0.25 }]]),
            tokenFlow: _defaultArr(opts.tokenFlow, ["consume-path-segment"]),
            takeoverRequest: opts.takeoverRequest || ["explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
            takeoverAccept: opts.takeoverAccept || ["accept-dominated-claims"],
            expand: _defaultArr(opts.expand, ["expand-when"]),
            retainParent: _defaultArr(opts.retainParent, ["retain-always"]),
            defaultAction: _defaultArr(opts.defaultAction, ["default-action-owner"]),
            riskGate: _defaultArr(opts.riskGate, ["risk-gate"])
        }
    };
}
