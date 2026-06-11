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

## IPC Debugging Shape

Use `newshell ipc call query search '<query>'` for the full search payload and `newshell ipc call query visual '<query>'` for the UI-facing, truncated payload.

Source of truth: `configs/quickshell/launcher/LauncherController.qml`, especially `querySearch()`, `queryVisual()`, `queryComplete()`, `queryBackends()`, and related `query*()` methods. Check that file before asserting the IPC JSON shape changed.

New debug endpoints (version 2): `queryPipeline()`, `queryPolicies()`, `queryScore()`, `queryShape()`, `queryCases()`, `queryRunCases()`. These are exposed through `Launcher.qml` as `queryPipeline()`, `queryPolicies()`, `queryScore()`, `queryShape()`, `queryCases()`, `queryRunCases()` and through `ShellState.qml` IPC as `pipeline`, `policies`, `score`, `shape`, `benchmark`, `cases`, `runCases`.

Pipeline model modules live in `configs/quickshell/launcher/logic/`: `PolicySpec.qml` (spec normalization), `PolicyDiagnostics.qml` (from `pipeline/`), `ScoreBundle.qml` (score parts with coverage), `ResultShaping.qml` (placement decisions retains placement/decision/shaped metadata), `PresentationContext.qml` (placement-sensitive display choices), `RenderedRows.qml` (row DTO construction consumes shaped items + presentation context).

Current `search` and `visual` envelopes are defined there in this form:

```json
{
  "version": 1,
  "type": "search|visual",
  "query": { "raw": "audio", "tokens": [{ "raw": "audio", "normalized": "audio" }], "isEmpty": false, "lastTokenEmpty": false },
  "directive": { "active": false, "prefix": "", "label": "All", "backendIds": [] },
  "totalResults": 2,
  "maxResults": 12,
  "results": [],
  "navigationTargets": []
}
```

Filtering notes:

- `search` omits `maxResults` and `navigationTargets`.
- Rows are under `.results[]`, not `.rows[]`.
- `visual` is the rendered-launcher view; prefer it when checking explicit prefixes or zero-score browse rows such as `@apps`.
- `search` can include rows with `ownVisible: false`; filter those out for ranking checks unless debugging hidden candidates.
- `evidence` currently returns `{version,type,resultId,found,evidence}` and may return `found: false` if the IPC cache does not contain that result id.
- `score` (version 2) returns `{version,type,resultId,found,scoreBundle,evidenceSummary}` with full `ScoreBundle` parts.
- `pipeline` (version 2) returns `{version,type,query,directive,timings,stages,diagnostics}`.
- `policies` (version 2) returns `{version,type,query,activeBackends,policiesByKind,diagnostics}`.
- `shape` (version 2) returns `{version,type,query,shapedResults}` with placement metadata per row from actual `ResultShaping` decisions. Fields: `title`, `nodeId`, `placement`, `depth`, `sortScore`, `score`, `ownScore`, `inheritedScore`, `descendantScore`, `ranking`, `group`, `activation`, `showParent`, `showBreadcrumbs`, `children`, `mode`, `reason`.
- `pipeline` (version 2, extended) now includes `shapingSummary` with placement counts and `tokenFlow` placeholder.
- `policies` (version 2, extended) now returns normalized policy specs with `name`, `baseName`, `args`, `priority`, `count` per kind.

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
