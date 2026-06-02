.pragma library

function defaultAction(result) {
  var actions = result && result.actions ? result.actions : [];
  return actions.find(function(a) { return a.default; }) || actions[0] || null;
}
