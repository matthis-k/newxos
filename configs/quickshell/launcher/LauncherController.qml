import QtQuick
import QtQml
import "logic/"
import "logic/RoutingTree.js" as RoutingTree
import "controllers" as Controllers
import "policies" as P

Item {
    id: root

    property alias query: searchSession.query
    property var backends: []
    property alias results: navigation.results
    property var routingTree: RoutingTree.makeTree()
    property alias selectedIndex: navigation.selectedIndex
    property alias selectedActionIndex: navigation.selectedActionIndex
    property alias loading: searchSession.loading
    property alias generation: searchSession.generation
    property alias _asyncGen: searchSession.asyncGeneration
    property int maxResults: 12
    property real visibilityThreshold: 0.18
    property bool includePath: true
    property bool showHidden: false
    property int maxTreeDepth: 4
    property alias expandedNodeIds: navigation.expandedNodeIds
    property alias collapsedResultIndices: navigation.collapsedResultIndices
    property alias lastQuery: navigation.lastQuery
    property alias lastDirective: navigation.lastDirective
    property alias lastEvaluatedRoot: navigation.lastEvaluatedRoot
    property alias asyncBackendQueries: searchSession.asyncBackendQueries
    property alias resultsQuery: navigation.resultsQuery
    property bool debugEnabled: false
    property string lastAsyncVisualJson: ""
    property alias pendingConfirmId: actions.pendingConfirmId
    property alias pendingConfirmTimeoutMs: actions.pendingConfirmTimeoutMs

    // Tree navigation state
    property alias currentTreeView: navigation.currentTreeView
    property alias currentTreeKey: navigation.currentTreeKey
    property alias treeVisualRow: navigation.treeVisualRow
    readonly property bool inTree: navigation.inTree
    property alias resultTreeViews: navigation.resultTreeViews
    property alias resultView: navigation.resultView
    property alias activeNodeKey: navigation.activeNodeKey

    signal queryReplacementRequested(string text)
    signal queryUpdateRequested(string text)
    signal resetRequested()
    signal resultsClearRequested()
    signal resultsRefreshRequested()
    signal collapseResultExpanded(int resultIndex)
    signal expandResultExpanded(int resultIndex)
    signal selectionResetRequested()
    signal asyncLoadingRefreshRequested()
    signal asyncBackendSearchStarted(var backend, string key, string text)
    signal asyncBackendResultsReceived(var backend, string key, string text, int generation, var update)
    signal searchRequested(string text, int generation)
    signal searchStarted(string text, int generation)
    signal searchCompleted(string text, int generation, var output)
    signal resultsAvailable(string text, int generation, var rows, var output)
    signal treeSwitchRefreshRequested(int resultIndex)

    Controllers.LauncherSearchSession {
        id: searchSession
        controller: root
        backends: root.backends
        routingTree: root.routingTree
        maxResults: root.maxResults

        onResultsClearRequested: root.resultsClearRequested()
        onSearchStarted: function(text, requestGeneration) {
            root.searchStarted(text, requestGeneration);
        }
        onSearchCompleted: function(text, requestGeneration, output) {
            root.searchCompleted(text, requestGeneration, output);
        }
        onResultsAvailable: function(text, requestGeneration, rows, output) {
            root.resultsAvailable(text, requestGeneration, rows, output);
        }
    }

    Controllers.LauncherNavigationState {
        id: navigation
        controller: root
    }

    Controllers.LauncherActionController {
        id: actions
        controller: root
    }

    Controllers.LauncherDebugController {
        id: debugController
        controller: root
    }

    P.UsagePolicy {}
    P.RecencyPolicy {}
    P.SemanticPolicy {}
    P.TokenClaimPolicy {}
    P.SwitchActionPolicy {}
    P.SwitchAliasesBoostPolicy {}
    P.FieldMatchPolicy { policyId: "field-match:all"; filterType: "all" }
    P.FieldMatchPolicy { policyId: "field-match:primary"; filterType: "primary" }
    P.FieldMatchPolicy { policyId: "field-match:breadcrumb"; filterType: "breadcrumb" }
    P.PathEvidencePolicy {}
    P.DescendantBoostPolicy { policyId: "descendant-boost" }
    P.VisibleFlagPolicy {}
    P.HasOwnScorePolicy {}
    P.AboveMinScorePolicy { policyId: "above-min-score:0.25"; threshold: 0.25 }
    P.OwnScoreMinPolicy { policyId: "own-score-min:0.25"; threshold: 0.25 }
    P.CandidateOrVisiblePolicy {}
    P.HasEvidencePolicy {}
    P.OwnScoreBeatsParentPolicy {}
    P.ScoreDominatesPolicy { policyId: "score-dominates:0.03"; margin: 0.03 }
    P.ScoreDominatesPolicy { policyId: "score-dominates:0.08"; margin: 0.08 }
    P.OwnScoreDominatesPolicy { policyId: "own-score-dominates:0.08"; margin: 0.08 }
    P.ScoreBeatsParentPolicy {}
    P.PresentationChainPolicy {}
    P.ExpandOnTrailingSpace {}

    QtObject {
        Component.onCompleted: PolicyRegistry.registerBaseNameAliases()
    }

    onQueryUpdateRequested: function(text) { searchSession.updateQuery(text); }
    onResetRequested: function() { searchSession.reset(); lastAsyncVisualJson = ""; }
    onResultsClearRequested: function() { navigation.clearResults(); }
    onResultsRefreshRequested: function() { navigation.refreshResults(); }
    onSelectionResetRequested: function() { navigation.resetSelection(); }
    onAsyncLoadingRefreshRequested: function() { searchSession.refreshLoading(); }
    onAsyncBackendSearchStarted: function(backend, key, text) { searchSession.beginAsyncBackendSearch(backend, key, text); }
    onAsyncBackendResultsReceived: function(backend, key, text, requestGeneration, update) { searchSession.receiveAsyncBackendResults(backend, key, text, requestGeneration, update); }
    onSearchRequested: function(text, requestGeneration) { searchSession.requestSearch(text, requestGeneration); }
    onResultsAvailable: function(text, requestGeneration, rows, output) {
        if (!output || requestGeneration !== root.generation || text !== root.query)
            return;

        lastQuery = output.query;
        lastDirective = output.directive;
        lastEvaluatedRoot = output.evaluatedRoot;
        setResults(rows, text);
    }

    // Navigation/state façade
    function clearSearchOutputState() { navigation.clearSearchOutputState(); }
    function queryIsEmptyForSelection() { return navigation.queryIsEmptyForSelection(); }
    function hasActivation(row) { return navigation.hasActivation(row); }
    function isSelectable(row) { return navigation.isSelectable(row); }
    function isRowSelectable(row) { return navigation.isRowSelectable(row); }
    function selectedResult() { return navigation.selectedResult(); }
    function rowKey(row) { return navigation.rowKey(row); }
    function setResults(newResults, sourceQuery) { navigation.setResults(newResults, sourceQuery); }
    function registerResultTreeView(index, treeView) { navigation.registerResultTreeView(index, treeView); }
    function moveSelection(delta) { navigation.moveSelection(delta); }
    function navigationTargets() { return navigation.navigationTargets(); }
    function resolveTreeViewAtIndex(index) { return navigation.resolveTreeViewAtIndex(index); }
    function applyNavigationTarget(target) { navigation.applyNavigationTarget(target); }
    function findTreeVisualRow(treeView, key) { return navigation.findTreeVisualRow(treeView, key); }
    function resetTreeNavigation() { navigation.resetTreeNavigation(); }
    function enterTree(result, treeView) { return navigation.enterTree(result, treeView); }
    function toggleCollapseResultTree() { return navigation.toggleCollapseResultTree(); }
    function toggleExpandResultTree() { return navigation.toggleExpandResultTree(); }
    function exitTree() { navigation.exitTree(); }
    function isInTree() { return navigation.isInTree(); }
    function moveInTree(delta) { navigation.moveInTree(delta); }
    function treeCollapseSelected() { return navigation.treeCollapseSelected(); }
    function treeExpandSelected() { return navigation.treeExpandSelected(); }
    function treeToggleSelected() { return navigation.treeToggleSelected(); }
    function findTreeRowData(key) { return navigation.findTreeRowData(key); }
    function findInChildren(row, key) { return navigation.findInChildren(row, key); }
    function findParentResultByKey(key) { return navigation.findParentResultByKey(key); }
    function loadLazyChildren(key) { navigation.loadLazyChildren(key); }

    // Debug/IPC façade
    function serializeRow(row) { return debugController.serializeRow(row); }
    function serializeRowsForQuery(rows, queryInfo) { return debugController.serializeRowsForQuery(rows, queryInfo); }
    function _resolveQueryArg(text) { return debugController.resolveQueryArg(text); }

    function buildDirectiveFromRoute(rawQuery, route) { return Engine.buildDirectiveFromRoute(rawQuery, route, backends || []); }
    function findHelpTitle(backendId) { return Engine.findHelpTitle(backends || [], backendId); }

    function debugBenchmark(arg) { return debugController.debugBenchmark(arg); }
    function parseBenchmarkConfig(arg) { return debugController.parseBenchmarkConfig(arg); }
    function debugVisualRows(text) { return debugController.debugVisualRows(text); }
    function debugApplyQuery(text) { return debugController.debugApplyQuery(text); }
    function debugVisualOutput(text, output) { return debugController.debugVisualOutput(text, output); }
    function queryPipeline(text) { return debugController.queryPipeline(text); }
    function queryPolicies(text) { return debugController.queryPolicies(text); }
    function collectActivePolicies(ev) { return debugController.collectActivePolicies(ev); }
    function queryCases() { return debugController.queryCases(); }
    function queryRunCases() { return debugController.queryRunCases(); }
    function regressionCaseQueries() { return debugController.regressionCaseQueries(); }
    function summarizeCaseResults(results) { return debugController.summarizeCaseResults(results); }

    // Search/session façade
    function stateForSearch() {
        return {
            selectedNodeId: selectedResult() ? selectedResult().nodeId : null,
            expandedNodeIds: expandedNodeIds || {}
        };
    }

    function searchOptions() {
        return {
            routingTree: root.routingTree,
            visibilityThreshold: visibilityThreshold,
            includePath: includePath,
            showHidden: showHidden,
            maxTreeDepth: maxTreeDepth
        };
    }

    function updateQuery(text) { queryUpdateRequested(text || ""); }
    function triggerAsyncBackends(text, currentGeneration) { searchSession.triggerAsyncBackends(text, currentGeneration); }
    function hasPendingAsyncBackends() { return searchSession.hasPendingAsyncBackends(); }
    function reset() { resetRequested(); }
    function backendId(backend) { return backend ? backend.backendId || "" : ""; }

    // Activation/action façade
    function activateSelected(shiftPressed) { return actions.activateSelected(shiftPressed); }
    function requiresConfirm(activation) { return actions.requiresConfirm(activation); }
    function completeSelected() { return actions.completeSelected(); }
    function activateResult(result, action) { return actions.activateResult(result, action); }
    function executeRecipeSlot(target, slotName) { return actions.executeRecipeSlot(target, slotName); }
    function applyIntent(result, intent) { return actions.applyIntent(result, intent); }
    function activateResultAction(result, actionId) { return actions.activateResultAction(result, actionId); }
    function adjustSelectedValue(delta) { return actions.adjustSelectedValue(delta); }
    function toggleSelectedMute() { return actions.toggleSelectedMute(); }
    function alignedControlValue(current, delta, step, from, to) { return actions.alignedControlValue(current, delta, step, from, to); }
    function refreshSwitchResult(result, action) { actions.refreshSwitchResult(result, action); }
    function activateTreeRowByKey(key, actionId) { return actions.activateTreeRowByKey(key, actionId); }
    function treeActivateCurrent() { return actions.treeActivateCurrent(); }
    function runRecipe(recipe, target) { return actions.runRecipe(recipe, target); }
    function runRecipeSlot(slotName) { return actions.runRecipeSlot(slotName); }
    function runInteractionForKey(keyName) { return actions.runInteractionForKey(keyName); }
    function effectiveRecipeForTarget(target, slotName) { return actions.effectiveRecipeForTarget(target, slotName); }
    function effectiveInteractionsForTarget(target) { return actions.effectiveInteractionsForTarget(target); }
    function _legacyApplyIntent(result, intent) { return actions._legacyApplyIntent(result, intent); }
    function _handleActivationWithConfirm() { return actions._handleActivationWithConfirm(); }
    function selectedActionTarget() { return actions.selectedActionTarget(); }
}
