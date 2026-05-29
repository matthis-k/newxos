.pragma library

function slugify(text) {
  return (text || "").toString().toLowerCase()
    .replace(/[\s_]+/g, "-")
    .replace(/[^a-z0-9-]/g, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

function deterministicHash(text, length) {
  var str = (text || "").toString();
  var hash = 0;
  for (var i = 0; i < str.length; i += 1) {
    var chr = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + chr;
    hash = hash & hash;
  }
  var hex = Math.abs(hash).toString(16);
  return hex.slice(0, length || 4);
}

function pickSegment(node, siblingIndex) {
  if (node.id && node.id.length > 0)
    return node.id;

  if (node.title && node.title.length > 0)
    return slugify(node.title);

  return "item-" + (siblingIndex != null ? siblingIndex : 0);
}

function generateNodeId(opts) {
  var backendId = opts.backendId || "unknown";
  var parentId = opts.parentId || "";
  var node = opts.node || {};
  var siblingIndex = opts.siblingIndex != null ? opts.siblingIndex : 0;
  var segment = pickSegment(node, siblingIndex);

  if (parentId)
    return parentId + "." + segment;

  return backendId + "." + segment;
}

function generateCandidateId(opts) {
  var backendId = opts.backendId || "unknown";
  var nodeId = opts.nodeId || "";
  var actionId = opts.actionId || "";

  if (actionId)
    return backendId + "." + nodeId + "." + actionId;

  return backendId + "." + nodeId;
}

function resolveCollision(existingIds, baseId, maxAttempts) {
  if (!existingIds || !existingIds[baseId])
    return baseId;

  for (var i = 1; i <= (maxAttempts || 99); i += 1) {
    var candidate = baseId + "-" + i;
    if (!existingIds[candidate])
      return candidate;
  }

  return baseId + "-" + deterministicHash(baseId, 4);
}

function walkTree(tree, backendId, parentId, siblingIndex) {
  var existingIds = {};
  var results = [];

  function walk(nodes, parentPath) {
    for (var i = 0; i < (nodes || []).length; i += 1) {
      var node = nodes[i];
      var segment = pickSegment(node, i);
      var candidateId = parentPath ? parentPath + "." + segment : backendId + "." + segment;
      var resolvedId = resolveCollision(existingIds, candidateId);
      existingIds[resolvedId] = true;

      var result = {
        node: node,
        id: resolvedId,
        parentPath: parentPath,
        segment: segment
      };
      results.push(result);

      if (node.children && node.children.length > 0)
        walk(node.children, resolvedId);
    }
  }

  walk(tree, parentId || "");
  return results;
}

function generateTreeIds(tree, backendId) {
  return walkTree(tree, backendId, "", 0);
}
