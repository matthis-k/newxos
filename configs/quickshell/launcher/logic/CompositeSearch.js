.pragma library
.import "CompositeSearchText.js" as Text
.import "CompositeSearchIndex.js" as Index
.import "AsyncSearchPipeline.js" as Pipeline
.import "RoutingTree.js" as RoutingTree

function tokenize(rawQuery) { return Text.tokenize(rawQuery); }
function parseDirective(rawQuery, backends) { return Text.parseDirective(rawQuery, backends); }
function makeAction(id, label, payload) { return Text.makeAction(id, label, payload); }
function makeNode(props) { return Text.makeNode(props); }
function buildSearchIndex(root) { return Index.buildSearchIndex(root); }
function search(backends, rawQuery, state, options) {
    var opts = Object.assign({}, options || {}, { sync: true });
    return Pipeline.searchAsync(backends, rawQuery, state, opts, function() { return true; }, null);
}
function routeQuery(tree, raw) { return RoutingTree.routeQuery(tree, raw); }
function makeRoutingTree() { return RoutingTree.makeTree(); }
function registerRoutingEndpoint(tree, route, node) { return RoutingTree.registerEndpoint(tree, route, node); }
function unregisterRoutingEndpoint(tree, node) { return RoutingTree.unregisterEndpoint(tree, node); }
