.pragma library

var namedPrefixes = ["@app", "@apps", "@desktop", "@calc", "@calculator", "@web", "@g", "@ddg", "@gh", "@yt", "@file", "@files"];
var symbolicPrefixes = [":", "=", ">", "?"];

var prefixToBackend = {
  ":": "desktop-actions",
  "!": "desktop-actions",
  "=": "calculator",
  ">": "shell",
  "?": "backends",
  "@app": "desktop",
  "@apps": "desktop",
  "@desktop": "desktop",
  "@calc": "calculator",
  "@calculator": "calculator",
  "@web": "web",
  "@g": "web",
  "@ddg": "web",
  "@gh": "web",
  "@yt": "web",
  "@file": "files",
  "@files": "files"
};

var namedPrefixEngines = {
  "@web": "default",
  "@g": "g",
  "@ddg": "ddg",
  "@gh": "gh",
  "@yt": "yt"
};

function parsePrefix(raw) {
  var s = String(raw || "").replace(/^\s+/, "");

  var sortedNamed = namedPrefixes.slice().sort(function(a, b) { return b.length - a.length; });
  for (var i = 0; i < sortedNamed.length; i += 1) {
    var p = sortedNamed[i];
    if (s === p)
      return { prefix: p, body: "" };

    if (s.startsWith(p)) {
      var next = s[p.length];
      if (next === undefined || /\s/.test(next) || next === ":" || next === "/") {
        return {
          prefix: p,
          body: s.slice(p.length).replace(/^[:\s]+/, "")
        };
      }
    }
  }

  for (var j = 0; j < symbolicPrefixes.length; j += 1) {
    var sp = symbolicPrefixes[j];
    if (s.startsWith(sp)) {
      return {
        prefix: sp,
        body: s.slice(sp.length).replace(/^\s+/, "")
      };
    }
  }

  return { prefix: undefined, body: raw };
}

function parse(query) {
  var raw = String(query || "").trim();
  if (!raw)
    return { raw: "", text: "", body: "", prefix: null, targetBackend: null, explicit: false, engine: null, tokens: [], explicitPathMode: false };

  var parsed = parsePrefix(raw);
  var body = parsed.body || "";
  var prefix = parsed.prefix;
  var toks = String(body || "").trim().split(/\s+/).filter(function(token) { return token.length > 0; });

  var hasPathSep = body.indexOf("/") >= 0 || body.indexOf("\u203A") >= 0;

  return {
    raw: raw,
    text: body,
    body: body,
    prefix: prefix || null,
    targetBackend: prefix ? prefixToBackend[prefix] : null,
    engine: prefix ? namedPrefixEngines[prefix] : null,
    explicit: !!prefix,
    tokens: toks,
    explicitPathMode: hasPathSep
  };
}

