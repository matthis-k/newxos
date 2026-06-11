---
name: launcher-search-change
description: Use when changing launcher backends, tokenization, evidence, scoring, flattening, row DTOs, prefix gating, async search, or launcher result rendering.
---

# Launcher Search Change

Use this skill for search behavior in `configs/quickshell/launcher/`.

## Inspect First

- Read launcher architecture in `docs/architecture.md`.
- Read launcher anti-patterns in `docs/contracts/quickshell-design.md`.
- Read launcher pitfalls in `docs/pitfalls.md`.
- Inspect the owning backend or logic file before editing.

## Architecture Boundary

- Backends produce normalized tree DTOs or result inputs.
- Composite search owns indexing, candidate collection, evidence, scoring, flattening, and row generation.
- Result rows carry primitive fields, actions, and evidence metadata only.
- UI delegates render normalized rows; they do not recompute scoring or hold backend references.
- Prefix gating controls backend participation through `canHandle(query)`.
- Async backends must respect generation counters before applying results.

## Procedure

1. Identify whether the change is backend input, scoring/evidence, flattening, row DTO, or UI rendering.
2. Keep data crossing boundaries plain and serializable.
3. Preserve web fallback behavior: explicit web prefixes or no visible non-web results.
4. Avoid broad rewrites; change the smallest owner.
5. Check ranking expectations after behavior changes.

## newshell CLI and service

`newshell` is a wrapper script around `quickshell -p <config-dir>` (see `modules/desktop/wrappers/quickshell.nix`). In dev mode (`NEWXOS_DEV=1`) it uses the live config from `$NEWXOS_FLAKE/configs/quickshell` and passes `--verbose`.

The systemd user service `newshell` (`systemctl --user restart newshell`) restarts the Quickshell session. All `newshell ipc` subcommands route IPC calls to the running instance identified by the config directory — you don't need to specify which instance.

Key subcommands:
- `newshell ipc call query <method> [arg]` — invokes a named IPC query method (search, visual, complete, backends, routes, evidence, result, state, pipeline, policies, score, shape, cases, runCases, benchmark)
- Arguments after `query <method>` are passed as raw strings to the method

## IPC Debugging Shape

Use `newshell ipc call query pipeline '<query>'` for the universal debug endpoint — returns rows, phases, backends, timings, and state in one call. Filter with `jq`: `jq '.rows[]'`, `jq '.phases[] | select(.name == "evaluation")'`, `jq '.backends.entries'`.

Source of truth: `configs/quickshell/launcher/LauncherController.qml`, especially `queryPipeline()`. Check that file before asserting the IPC JSON shape changed.

Debug endpoints: `queryPipeline()` returns per-phase snapshots and serialized rows. `queryPolicies()` returns active policy catalog. `queryCases()` and `queryRunCases()` handle regression testing. These are exposed through `Launcher.qml` and `ShellState.qml` IPC as `pipeline`, `policies`, `benchmark`, `cases`, `runCases`.

Pipeline model modules live in `configs/quickshell/launcher/logic/`: `PolicySpec.qml` (spec normalization), `PolicyChain.qml` (policy aggregation + `lookupPolicy` helper for normalized spec-aware lookups), `ScoreBundle.qml` (score parts with coverage), `ResultShaping.qml` (placement decisions retains placement/decision/shaped metadata), `PresentationContext.qml` (placement-sensitive display choices), `RenderedRows.qml` (row DTO construction consumes shaped items + presentation context). TokenFlowDecision is not implemented yet. ActionPolicy is not extracted yet.

`pipeline` (version 3) is the universal debug endpoint. Shape:

```json
{
  "version": 3, "type": "pipeline",
  "query": "audio",
  "directive": { "active": false, "prefix": "", "label": "All", "backendIds": [] },
  "timings": { "totalMs": 2.3, "shapeMs": 0.4, ... },
  "phases": [
    { "phase": 0, "name": "directive-tokenize", "tokens": [...], "activeBackendIds": [...] },
    { "phase": 1, "name": "root-nodes", "roots": [...] },
    { "phase": 2, "name": "candidates", "candidateCount": 42 },
    { "phase": 3, "name": "evaluation", "childScoreBundles": [...] },
    { "phase": 4, "name": "path-policies", "pathMs": 0.1 },
    { "phase": 5, "name": "shaping", "shaped": [...], "placements": {...} }
  ],
  "rows": [{ "id": "...", "title": "...", "score": 0.8, ... }],
  "totalResults": 5,
  "backends": { "total": 8, "entries": [...], "routingTree": {...} },
  "state": { "selectedIndex": 0, "resultCount": 5, "loading": false },
  "diagnostics": {...}
}
```

Filtering notes:

- Rows are under `.rows[]` — same shape as the old `search`/`visual` `.results[]`.
- `.phases[]` — select by `.name` or `.phase` number. Phase 0 covers directive/tokens/backends, phase 3 covers scores, phase 5 covers shaping.
- `.backends.entries[]` — full backend metadata.
- Filter hidden candidates with `.rows[] | select(.ownVisible == true)`.
- `policies` (version 2) returns `{version,type,query,activeBackends,policiesByKind,diagnostics}`.
- `hitCount` and `hitCountUpper` live on the `scoreBundle` inside each row's `.scoreBundle` field.

Useful row fields for `jq`: `id`, `title`, `subtitle`, `source`, `kind`, `score`, `ownScore`, `descendantScore`, `matchDepth`, `ownVisible`, `executable`, `dangerous`, `actions`, `evidence`, `children`, `switchState`, `control`, `breadcrumbs`, `breadcrumbText`, `placement`, `presentationContext`, `scoreBundle`.

Start with these filters:

```bash
newshell ipc call query search 'audio' \
  | jq '{query:.query.raw, directive, rows:[.results[] | select(.ownVisible == true) | {title, subtitle, source, kind, score, ownScore, matchDepth, actions, children:(.children // [] | length)}]}'

newshell ipc call query visual 'audio' \
  | jq '{query:.query.raw, totalResults, directive, rows:[.results[] | {title, source, kind, score, children:(.children // [] | map({title, kind, score}))}], navigationTargets:[.navigationTargets[]? | {title, treeDepth}]}'

for q in '<partial app name or shorthand>' '<app name plus sub-action word>' '<control name plus desired state>' '<backend prefix alone or with terms>' '<absolute or home-relative path>' '<ordinary web-search phrase>'; do
  newshell ipc call query visual "$q" \
    | jq --arg q "$q" '{query:$q, totalResults, directive, rows:[.results[] | {title, subtitle, source, kind, score, children:(.children // [] | length)}] | .[0:8]}'
done
```

## Capability Use Cases

Keep this list aligned with launcher capabilities. When adding, removing, or changing a backend, row kind, prefix, action family, or fallback behavior, update these use cases so future sanity checks cover the current launcher surface.

Run or manually inspect query forms a user might type when trying to. Choose concrete examples from installed apps, available actions, current devices, and familiar local shorthand; do not preserve stale hard-coded examples.

- Partial app name, app acronym, or user shorthand.
- App name plus a sub-action word such as a window/profile/private/action intent.
- Desktop/system action name, category name, or category plus action text.
- Stateful control name alone, and control name plus desired state/action word.
- Continuous control name with level/adjustment intent.
- Group/category name alone, then group/category plus child intent.
- Backend prefix alone for browse mode.
- Backend prefix plus search terms for scoped search.
- Familiar shorthand for a dashboard, system, settings, or workflow area.
- Absolute path, home-relative path, or path fragment.
- Calculator expression or unit/value style input.
- Help/backend browser prefix or help-oriented query form.
- Ordinary phrase that should use web fallback because no local non-web result is visible.
- Explicit web prefix plus search terms.
- Misspelled or transposed form of a query that should still recover without outranking stronger exact/prefix/common matches.

## Do Not

- Keep whole evaluated trees in result rows.
- Treat permission alone as evidence of relevance.
- Prewarm backends whose source model populates asynchronously.
- Let web fallback compete when non-web visible rows exist.
