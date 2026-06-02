.pragma library
.import "CompositeSearchText.js" as Text
.import "CompositeSearchIndex.js" as Index
.import "CompositeSearchPipeline.js" as Pipeline

function tokenize(rawQuery) { return Text.tokenize(rawQuery); }
function parseDirective(rawQuery, backends) { return Text.parseDirective(rawQuery, backends); }
function makeAction(id, label, payload) { return Text.makeAction(id, label, payload); }
function makeNode(props) { return Text.makeNode(props); }
function buildSearchIndex(root) { return Index.buildSearchIndex(root); }
function search(backends, rawQuery, state, options) { return Pipeline.search(backends, rawQuery, state, options); }
