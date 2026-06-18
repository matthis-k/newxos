# Launcher sanity check

Use this when changing launcher scoring, flattening, backend participation, row rendering, or IPC-facing result shape.

## Ranking Goals

- Scores are per-node positive evidence scores, not global normalization across all candidates.
- Text evidence should communicate why a row matched: exact, prefix, compact, substring, acronym, fuzzy, semantic, token-policy, switch alias, usage/recency, and path/ancestor evidence.
- More direct/common actions should usually beat rarer or indirect actions unless the query contains evidence for the rare action.
- Parent/group rows should not clutter results with children by default. Show more children when a prefix has no further tokens, the query has a trailing space, or the parent match intentionally exposes direct children.
- Results should be forward stable while typing. If two rows match the same text path, avoid major order shakeups as the query grows.
- Prefixes gate intent. Explicit prefixes can show broader scoped rows; ambient search should stay compact.
- Fuzzy matching should recover likely typos without overwhelming exact/prefix/common matches.

## Stability Examples

These examples are not a fixed regression suite; they describe the underlying rule.

- `networking wifi` and `dashboard wifi` should not randomly trade places while typing `wifi` if both are matching the same visible token.
- `audio` should remain consistently visible across `a`, `au`, `aud`, `audi`, and `audio` instead of appearing only on the final character.
- Common switch actions like Wi-Fi toggle/on/off should beat unrelated lower-frequency actions unless the query names the other action.
- `zen` should prefer the common app/group result, while `zen private` or `zen window` can prefer those specific child actions.

## IPC Debugging

Keep the launcher IPC available for manual checks:

```bash
newshell ipc call query pipeline '<query>'    # Compact visible rows plus phases, backends, timings
newshell ipc call query pipeline '{"query":"ze","focusNodeId":"desktop:apps:zen_beta"}' # Focus one hidden/evaluated node family
newshell ipc call query policies '<query>'    # Active policy specs per kind
newshell ipc call query benchmark '{"queries":["zen","wifi"],"iterations":2}'
newshell ipc call query cases
newshell ipc call query runCases
```

## Pipeline JSON Schema (version 3)

The `pipeline` endpoint is the universal debug output. Plain string queries use normal visible-row filtering. Use JSON with `focusNodeId` (or `nodeId`/`id`) when you need hidden/full evaluation for one specific node family; focused mode enables hidden evaluation but filters returned rows and phase details to matching node ids and descendants. Shape:

```json
{
  "version": 3, "type": "pipeline",
  "query": "audio",
  "directive": { "active": false, "prefix": "", "label": "All", "backendIds": [] },
  "timings": { "totalMs": 2.3, "shapeMs": 0.4 },
  "phases": [
    { "phase": 0, "name": "directive-tokenize", "tokens": [], "activeBackendIds": [] },
    { "phase": 1, "name": "root-nodes", "roots": [] },
    { "phase": 2, "name": "candidates", "candidateCount": 42 },
    { "phase": 3, "name": "evaluation", "childScoreBundles": [] },
    { "phase": 4, "name": "path-policies", "pathMs": 0.1 },
    { "phase": 5, "name": "shaping", "shaped": [], "placements": {} }
  ],
  "rows": [{ "id": "...", "title": "...", "score": 0.8 }],
  "totalResults": 5,
  "debug": { "focusNodeId": null, "showHidden": false, "unfilteredResults": 5 },
  "backends": { "total": 8, "entries": [], "routingTree": {} },
  "state": { "selectedIndex": 0, "resultCount": 5, "loading": false },
  "diagnostics": {}
}
```

Focused pipeline calls:

```bash
# Inspect how one desktop entry family is evaluated for a query, including hidden state.
newshell ipc call query pipeline '{"query":"ze","focusNodeId":"desktop:apps:zen_beta"}' \
  | jq '{debug, rows: [.rows[] | {title, nodeId, childTitles: [.children[]?.title]}], shaped: (.phases[] | select(.name == "shaping") | .shaped)}'
```

Do not use focused mode as a broad snapshot mechanism. If a payload is too large, narrow `focusNodeId` instead of enabling hidden output for all rows.

### Row Fields

Useful fields for `jq` filtering:

`id`, `title`, `subtitle`, `source`, `kind`, `score`, `ownScore`, `descendantScore`, `matchDepth`, `ownVisible`, `executable`, `dangerous`, `actions`, `evidence`, `children`, `switchState`, `control`, `breadcrumbs`, `breadcrumbText`, `placement`, `presentationContext`, `scoreBundle`.

### jq Filter Recipes

```bash
# Visible rows with key fields
newshell ipc call query pipeline 'audio' \
  | jq '.rows[] | select(.ownVisible == true) | {title, subtitle, source, kind, score, ownScore, matchDepth, children: (.children // [] | length)}'

# Actual child rows for visible groups
newshell ipc call query pipeline 'zen ' \
  | jq '.rows[] | {title, children: [.children[]?.title]}'

# Phase listing
newshell ipc call query pipeline 'audio' | jq '.phases[] | {phase, name}'

# Evaluation scores per backend root
newshell ipc call query pipeline 'audio' \
  | jq '.phases[] | select(.name == "evaluation").childScoreBundles[] | {label, score, ownScore}'

# Shaping decisions per item
newshell ipc call query pipeline 'audio' \
  | jq '.phases[] | select(.name == "shaping").shaped[] | {title, placement, score}'

# Backend metadata
newshell ipc call query pipeline 'audio' | jq '.backends.entries[] | {id, name, enabled}'

# Directive and tokens (phase 0)
newshell ipc call query pipeline 'zen priv' | jq '{directive, tokens: .phases[0].tokens}'

# Timing breakdown
newshell ipc call query pipeline 'audio' | jq '.timings'
```

### Phase Reference

| Phase | Name | Contents |
|-------|------|----------|
| 0 | directive-tokenize | Directive, tokens, active backend IDs |
| 1 | root-nodes | Backend root nodes |
| 2 | candidates | Candidate count per backend |
| 3 | evaluation | Score bundles per candidate |
| 4 | path-policies | Path-based policy timing |
| 5 | shaping | Per-item placement decisions |

## Capability Use Cases

When adding, removing, or changing a backend, row kind, prefix, action family, or fallback, verify these query forms still work. Choose concrete examples from installed apps, available actions, and current devices — do not preserve stale hardcoded examples.

- **Partial app name**, acronym, or user shorthand.
- **App plus sub-action**: app name with intent word (window, profile, private).
- **Desktop/system action**: action name, category, or category + action text.
- **Stateful control**: control name alone, and control + desired state.
- **Continuous control**: control name with level/adjustment intent.
- **Group/category**: group name alone, and group + child intent.
- **Backend prefix alone**: browse mode (shows root nodes for that backend).
- **Backend prefix + terms**: scoped search within a backend.
- **Familiar shorthand**: dashboard, system, settings, or workflow area name.
- **Path**: absolute path, home-relative path, or path fragment.
- **Calculator**: expression or unit/value style input.
- **Help/backend browser**: prefix or query form to discover backends.
- **Web fallback**: ordinary phrase where no non-web result should be visible.
- **Explicit web**: web prefix plus search terms.
- **Misspelled/transposed**: query that should recover without outranking stronger exact/prefix matches.

Always record the visible query when debugging GUI-only missing-row reports. A row can be absent because the visible launcher query differs from the query sent through IPC, because prefix parsing changed the effective search query, or because the GUI is showing stale/filtered rows.

## Debug Flow for Bad Results

Pipeline modules live in `configs/quickshell/launcher/logic/`: `Evaluate.qml` -> `ResultShaping.qml` (owns placement) -> `RenderedRows.qml` (builds rows from shaped items using `PresentationContext.qml`). `PolicyChain.lookupPolicy` provides normalized spec-aware lookups. `LauncherController.qml` is a compatibility façade; search/session behavior lives in `controllers/LauncherSearchSession.qml`, result/tree selection in `controllers/LauncherNavigationState.qml`, activation in `controllers/LauncherActionController.qml`, and IPC/debug serialization in `controllers/LauncherDebugController.qml`. TokenFlowDecision not implemented yet; ActionPolicy remains incremental.

1. `query pipeline` — universal endpoint. Check visible rows (`.rows`), phases (`.phases[]`), backends (`.backends`), timings (`.timings`). Use JSON `focusNodeId` when debugging a specific hidden or over-filtered entry.
   - `.phases[] | select(.name == "directive-tokenize")` — directive, tokens, active backends
   - `.phases[] | select(.name == "evaluation")` — score bundles per backend root
   - `.phases[] | select(.name == "shaping")` — per-item placements
   - `.rows[] | select(.ownVisible == true)` — final rendered rows
   - focused form: `query pipeline '{"query":"ze","focusNodeId":"desktop:apps:zen_beta"}'`
2. `query policies` — check normalized policy specs active per kind
3. `query benchmark` — run benchmarks with timing data

## When Logic Changes

- Run the narrow QuickShell check or `nix run "path:$PWD#repo-gate"` when practical.
- Manually sample representative queries with IPC for major search changes.
- Prefer a small set of intent-covering queries over large stored snapshots.
- Compare filtered fields with `jq`; avoid pasting full row payloads unless debugging row shape.
