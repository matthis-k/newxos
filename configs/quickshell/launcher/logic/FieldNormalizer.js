.pragma library

function caseFold(text) {
  return (text || "").toString().toLowerCase();
}

function normalizeUnicode(text) {
  return (text || "").toString().normalize ? (text || "").toString().normalize("NFKD") : (text || "").toString();
}

function removeDiacritics(text) {
  return normalizeUnicode(text).replace(/[\u0300-\u036f]/g, "");
}

function splitSeparators(text) {
  return (text || "").toString().split(/[\s-/]+/).filter(function(t) { return t.length > 0; });
}

function splitCamelCase(text) {
  var result = [];
  var current = "";
  for (var i = 0; i < (text || "").length; i += 1) {
    var ch = text[i];
    if (ch >= "A" && ch <= "Z" && current.length > 0) {
      result.push(current.toLowerCase());
      current = ch;
    } else {
      current += ch;
    }
  }
  if (current.length > 0)
    result.push(current.toLowerCase());
  return result;
}

function tokenize(text) {
  var step1 = caseFold(text);
  var step2 = removeDiacritics(step1);
  var step3 = step2.replace(/([a-z])([A-Z])/g, "$1 $2");
  var raw = step3.split(/[\s-/._]+/);
  var tokens = [];
  for (var i = 0; i < raw.length; i += 1) {
    var t = raw[i].trim();
    if (t.length > 0)
      tokens.push(t);
  }
  return tokens;
}

function compactForms(tokens) {
  var joined = tokens.join("");
  var firstLetters = tokens.map(function(t) { return t[0]; }).join("");
  var firstTwoLetters = tokens.map(function(t) { return t.slice(0, 2); }).join("");

  var result = [joined];
  if (firstLetters.length > 1)
    result.push(firstLetters);
  if (firstTwoLetters.length > 2 && firstTwoLetters !== joined)
    result.push(firstTwoLetters);

  return result;
}

function acronym(tokens) {
  var letters = tokens.map(function(t) { return t[0]; }).filter(function(c) { return c && c.length > 0; });
  return letters.join("");
}

function suffixPaths(path, maxDepth) {
  var result = [];
  for (var i = 0; i < (path || []).length; i += 1) {
    var suffix = path.slice(i).join(" ");
    if (suffix.length > 0)
      result.push(suffix);
    if (maxDepth && result.length >= maxDepth)
      break;
  }
  return result;
}

function normalizeField(value) {
  if (!value)
    return { raw: "", tokens: [], compact: [], acronym: "" };

  var raw = (value || "").toString();
  var toks = tokenize(raw);
  return {
    raw: raw,
    normalized: caseFold(raw),
    tokens: toks,
    compact: compactForms(toks),
    acronym: acronym(toks)
  };
}

function buildDerivedFields(title, path, actionTitle, aliases, keywords, description, subtitle) {
  var fields = [];

  if (actionTitle) {
    var n = normalizeField(actionTitle);
    fields.push({ key: "action-title", value: actionTitle, normalized: n, weight: 1.0 });
  }

  if (title) {
    var nTitle = normalizeField(title);
    fields.push({ key: "node-title", value: title, normalized: nTitle, weight: 1.0 });

    if (path && path.length > 0) {
      var suffixParts = suffixPaths(path, 1);
      for (var si = 0; si < suffixParts.length; si += 1) {
        var sf = normalizeField(suffixParts[si]);
        fields.push({ key: "suffix-path", value: suffixParts[si], normalized: sf, weight: 0.30 });
      }

      var fullPathStr = path.join(" ");
      var fp = normalizeField(fullPathStr);
      fields.push({ key: "full-path", value: fullPathStr, normalized: fp, weight: 0.20 });
    }
  }

  if (subtitle) {
    var nSub = normalizeField(subtitle);
    fields.push({ key: "subtitle", value: subtitle, normalized: nSub, weight: 0.60 });
  }

  if (aliases) {
    for (var ai = 0; ai < aliases.length; ai += 1) {
      var nAlias = normalizeField(aliases[ai]);
      fields.push({ key: "alias", value: aliases[ai], normalized: nAlias, weight: 0.90 });
    }
  }

  if (keywords) {
    for (var ki = 0; ki < keywords.length; ki += 1) {
      var nKw = normalizeField(keywords[ki]);
      fields.push({ key: "keyword", value: keywords[ki], normalized: nKw, weight: 0.70 });
    }
  }

  if (description) {
    var nDesc = normalizeField(description);
    fields.push({ key: "description", value: description, normalized: nDesc, weight: 0.35 });
  }

  return fields;
}

function combineQueryTokens(parsedQuery) {
  var tokens = parsedQuery.tokens || [];
  var result = [];
  for (var i = 0; i < tokens.length; i += 1)
    result.push(tokenize(tokens[i]));

  var flattened = [];
  for (var ri = 0; ri < result.length; ri += 1) {
    for (var rj = 0; rj < result[ri].length; rj += 1)
      flattened.push(result[ri][rj]);
  }
  return flattened;
}

function hasTokenMatch(needle, haystackTokens) {
  var nl = needle.toLowerCase();
  for (var i = 0; i < haystackTokens.length; i += 1) {
    if (haystackTokens[i] === nl)
      return true;
  }
  return false;
}

function isSubsequence(pattern, text) {
  var pi = 0;
  for (var ti = 0; ti < text.length && pi < pattern.length; ti += 1) {
    if (text[ti] === pattern[pi])
      pi += 1;
  }
  return pi === pattern.length;
}
