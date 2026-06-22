---
name: launcher-search-change
description: Use when changing launcher backends, tokenization, evidence, scoring, flattening, row DTOs, prefix gating, async search, or launcher result rendering.
---

# Launcher Search Change

## Core Rule

Launcher behavior changes should be policy-driven. Backend data must cross the DTO boundary as plain serializable objects. UI delegates render, they do not compute.

## Inspect First

- `docs/architecture.md` — launcher architecture section (pipeline, DTO boundary, prefix gating)
- `docs/contracts/quickshell-design.md` — anti-patterns section
- `docs/pitfalls.md` — launcher pitfalls (retained trees, circular references, children bypass)
- `docs/playbooks/launcher-sanity-check.md` — ranking intent, IPC debugging, pipeline schema, capability cases
- Owning backend or logic file in `configs/newshell/launcher/`

## Architecture Boundary

- **Backends** produce normalized tree DTOs (plain JS objects, no live QML refs).
- **Composite search** (`logic/`) handles indexing, evidence, scoring, flattening, row generation.
- **Result rows** carry primitive fields, actions, and evidence metadata only.
- **UI delegates** render normalized rows; no score recomputation or backend references.
- **Prefix gating** via `RoutingTree.js` — backends register routes in `Component.onCompleted`.
- **Async backends** check generation counters before applying results.

## Ownership Map

| Path | Owns |
|------|------|
| `launcher/LauncherController.qml` | Composite search orchestration, `queryPipeline()` |
| `launcher/Logic/Evaluate.qml` | Evidence collection, scoring, default dedup mode |
| `launcher/Logic/ResultShaping.qml` | Placement decisions (hidden, standalone, group, flattened, etc) |
| `launcher/Logic/RenderedRows.qml` | Row DTO construction from shaped items |
| `launcher/Logic/ActionPolicy.qml` | Default action candidate selection and scoring |
| `launcher/Logic/ActionRegistry.qml` | Recipe step execution and service payload dispatch |
| `launcher/Logic/RecipeResolver.qml` | Effective recipe and interaction resolution |
| `launcher/Logic/PresentationContext.qml` | Placement-sensitive display choices |
| `launcher/Logic/PolicyChain.qml` | Policy aggregation, `lookupPolicy()` |
| `launcher/Logic/PolicySpec.qml` | Policy spec normalization (legacy strings → canonical) |
| `launcher/Logic/ScoreBundle.qml` | Score parts with coverage |
| `launcher/Logic/Evidence.qml` | Evidence dedup (`bestPerToken` default) |
| `launcher/Logic/RoutingTree.js` | Prefix routing, backend gating |
| `launcher/backends/` | Backend DTOs and search |
| `launcher/policies/` | Individual policy implementations |
| `launcher/delegates/` | UI delegates rendering rows |
| `launcher/Launcher.qml` | IPC boundary, delegates to controller |

## Pipeline Flow

```
Directive/tokenize → Candidate collection → Evidence → Scoring → Path policies → Shaping → Row DTOs
```

## Change Routing

| Symptom | Edit |
|---------|------|
| Matching wrong or incomplete | Edit evidence/searchable-field config in backend or PolicyChain |
| Ranking wrong | Edit scoring/boost policy |
| Display wrong | Edit row DTO (`RenderedRows.qml`), presentation context, or delegate |
| Source data wrong | Edit backend DTO construction |
| Backend not participating | Check prefix/routing registration in backend's `Component.onCompleted` |
| Children missing after shaping | Check `Engine.qml:buildRowsFromShaped` — null vs empty `childEvs` |
| Web fallback appearing with visible results | Check web fallback gating in composite search |
| Row DTO field missing or wrong type | Update `RenderedRows.qml` and all consuming delegates |

## IPC Commands

```bash
newshell ipc call query pipeline '<query>'    # Universal debug — rows, phases, backends, timings
newshell ipc call query policies '<query>'    # Active policy specs per kind
newshell ipc call query benchmark '<json>'    # Benchmark queries via debugBenchmark()
newshell ipc call query cases                 # Active regression query list
newshell ipc call query runCases              # Run all regression cases
```

For the full pipeline JSON schema, detailed `jq` filter recipes, capability use cases, and debug flow guidance, see `docs/playbooks/launcher-sanity-check.md`.

## Do Not

- Keep whole evaluated trees in result rows.
- Treat permission alone as evidence of relevance.
- Prewarm backends whose source model populates asynchronously.
- Let web fallback compete when non-web visible rows exist.
- Put ranking or action-selection logic in UI delegates.
- Serialize raw QML objects in IPC responses.
- Remove legacy policy names without migration path.

## Deferred Architecture

Do not implement unless repeated concrete need:

- TokenFlowDecision
- Generic rule engine

## Done Criteria

- Smallest correct owner changed.
- Backend DTOs are plain serializable objects.
- Prefix gating unchanged unless intended.
- Web fallback behavior preserved.
- Ranking intent verified with representative queries.
- No raw QML objects in IPC responses.
- Docs/playbook updated only if the workflow changed.
