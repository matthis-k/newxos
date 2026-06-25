pragma Singleton
import QtQml

// Centralized evaluation profile factories.
// Reduces duplicate inline profile objects in backend files.
// Backends import this instead of defining their own profile functions.

Singleton {
    // Default action-group profile with consume-namespace-pass-rest token flow,
    // standard takeover/expand/retain policies, and field-match + semantic evidence.
    function groupProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                fields: opts.fields || ["label", "aliases"],
                evidence: opts.evidence || ["field-match", "switch-action", "semantic"],
                boost: opts.boost || ["descendant-boost"],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["consume-namespace-pass-rest"],
                takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : ["child-own-match-parent-no-own-match", "explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
                takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : ["accept-dominated-claims"],
                expand: opts.expand || ["expand-on-own-match-or-trailing-space"],
                retainParent: opts.retainParent || [{ name: "retain-parent-when", args: { condition: "own-match" } }],
                defaultAction: opts.defaultAction || ["default-action-expand"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    // Profile for VPN switch nodes with switch token flow and retain-always.
    function switchProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                fields: opts.fields || ["label", "aliases"],
                evidence: opts.evidence || ["field-match", ["field-match", { fields: ["breadcrumb"] }], "switch-action"],
                boost: opts.boost || ["descendant-boost", "switch-aliases"],
                childVisible: opts.childVisible || ["has-own-score"],
                tokenFlow: opts.tokenFlow || ["consume-switch-pass-rest"],
                takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : [],
                takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : [],
                expand: opts.expand || ["expand-on-own-match-or-trailing-space"],
                retainParent: opts.retainParent || ["retain-always"],
                defaultAction: opts.defaultAction || ["default-action-owner"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    // Leaf (desktop app) profile with consume-own-pass-rest token flow and trailing-space expand.
    function appProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                fields: opts.fields || ["label"],
                evidence: opts.evidence || [["field-match", { fields: ["label"] }], "semantic", "usage", "recency"],
                boost: opts.boost || ["descendant-boost"],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["consume-own-pass-rest"],
                takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : ["child-own-match-parent-no-own-match", "explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
                takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : ["accept-dominated-claims"],
                expand: opts.expand || ["expand-on-trailing-space"],
                retainParent: opts.retainParent || [{ name: "retain-parent-when", args: { condition: "own-match" } }],
                defaultAction: opts.defaultAction || ["default-action-owner"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    // Visual root (e.g., "Applications" heading) with pass-all token flow and own-match-or-trailing-space expand.
    function visualRootProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                fields: opts.fields || ["label"],
                evidence: opts.evidence || [["field-match", { fields: ["label"] }], "semantic"],
                boost: opts.boost || ["descendant-boost"],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["pass-all"],
                takeoverRequest: opts.takeoverRequest !== undefined ? opts.takeoverRequest : ["child-own-match-parent-no-own-match", "explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
                takeoverAccept: opts.takeoverAccept !== undefined ? opts.takeoverAccept : ["accept-dominated-claims"],
                expand: opts.expand || ["expand-on-own-match-or-trailing-space"],
                retainParent: opts.retainParent || [{ name: "retain-parent-when", args: { condition: "own-match" } }],
                defaultAction: opts.defaultAction || ["default-action-expand"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    // Minimal backend root profile for backend root nodes (TreeBackendBase, LauncherBackendBase).
    // No takeover/expand/retain policies. Mode is "generic" with "backend" score policy.
    function backendRootProfile(opts) {
        opts = opts || {};
        return {
            mode: opts.mode || "generic",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy"],
            scorePolicy: opts.scorePolicy || "backend",
            profile: {
                fields: opts.fields || ["label", "aliases"],
                evidence: opts.evidence || ["field-match"],
                boost: opts.boost || [],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["pass-all"],
                takeoverRequest: opts.takeoverRequest || [],
                takeoverAccept: opts.takeoverAccept || [],
                expand: opts.expand || [],
                retainParent: opts.retainParent || [],
                defaultAction: opts.defaultAction || [],
                riskGate: opts.riskGate || []
            }
        };
    }

    // Default node profile: pass-all token flow, no takeover/expand/retain.
    // Includes token-claim in evidence. Used by NodeFactory when a node has no explicit profile.
    function defaultNodeProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                fields: opts.fields || ["label", "aliases"],
                evidence: opts.evidence || ["field-match", "switch-action", "semantic", "token-claim", "usage", "recency"],
                boost: opts.boost || ["descendant-boost"],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["pass-all"],
                takeoverRequest: opts.takeoverRequest || [],
                takeoverAccept: opts.takeoverAccept || [],
                expand: opts.expand || [],
                retainParent: opts.retainParent || [],
                defaultAction: opts.defaultAction || ["default-action-owner"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    // Leaf node profile: pass-all token flow, no takeover/expand/retain.
    // Used by tree backends for leaf nodes (nodes without children).
    function leafProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
            scorePolicy: opts.scorePolicy || "default",
            profile: {
                fields: opts.fields || ["label", "aliases"],
                evidence: opts.evidence || ["field-match", "semantic", "token-claim", "usage", "recency"],
                boost: opts.boost || [],
                childVisible: opts.childVisible || ["visible-flag"],
                tokenFlow: opts.tokenFlow || ["pass-all"],
                takeoverRequest: opts.takeoverRequest || [],
                takeoverAccept: opts.takeoverAccept || [],
                expand: opts.expand || [],
                retainParent: opts.retainParent || [],
                defaultAction: opts.defaultAction || ["default-action-owner"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    // Calculator result profile: pass-all, semantic-result scoring, no boost/takeover.
    function calculatorProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic+custom",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym", "semantic"],
            scorePolicy: opts.scorePolicy || "semantic-result",
            profile: {
                fields: opts.fields || ["label", "aliases"],
                evidence: opts.evidence || ["field-match", "semantic"],
                boost: opts.boost || [],
                childVisible: opts.childVisible || ["visible-flag", ["above-min-score", { threshold: 0.25 }]],
                tokenFlow: opts.tokenFlow || ["pass-all"],
                takeoverRequest: opts.takeoverRequest || [],
                takeoverAccept: opts.takeoverAccept || [],
                expand: opts.expand || ["expand-none"],
                retainParent: opts.retainParent || ["retain-always"],
                defaultAction: opts.defaultAction || ["default-action-owner"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

    // File backend profile: consume-path-segment token flow, path field, expand-when.
    function fileProfile(opts) {
        opts = opts || {};
        return {
            mode: "generic",
            strategies: opts.strategies || ["exact", "prefix", "compact", "substring", "acronym"],
            scorePolicy: opts.scorePolicy || "backend",
            profile: {
                fields: opts.fields || ["label", "aliases", "path"],
                evidence: opts.evidence || ["field-match", "usage", "recency"],
                boost: opts.boost || ["descendant-boost"],
                childVisible: opts.childVisible || ["visible-flag", ["above-min-score", { threshold: 0.25 }]],
                tokenFlow: opts.tokenFlow || ["consume-path-segment"],
                takeoverRequest: opts.takeoverRequest || ["explicit-child-token", "child-covers-passed-tokens", "own-score-dominates-takeover"],
                takeoverAccept: opts.takeoverAccept || ["accept-dominated-claims"],
                expand: opts.expand || ["expand-when"],
                retainParent: opts.retainParent || ["retain-always"],
                defaultAction: opts.defaultAction || ["default-action-owner"],
                riskGate: opts.riskGate || ["risk-gate"]
            }
        };
    }

}
