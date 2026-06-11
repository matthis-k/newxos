# Launcher ranking expectations

Use `newshell ipc call query search '<query>'` or `newshell ipc call query visual '<query>'` after `systemctl --user restart newshell` to verify results. Source: `configs/quickshell/launcher/logic/` (QML pipeline modules).

## Core checklist

Run these queries after any launcher search change:

`?`, `? `, `?au`, `zen`, `zen `, `zen priv`, `zen win`, `zen browser`, `zen new`, `wifi`, `wifi `, `wifi on`, `wifi off`, `wifi toggle`, `toggle wifi`, `wo`, `wt`, `:`, `:wifi`, `:wifi `, `:wifi on`, `:db wifi`, `@apps`, `@apps zen`, `@apps wifi`, `@web nix`, `web nix`, `web !gh nix`, `db wifi`, `dashboard wifi`, `au`, `aud`, `audi`, `audio`, `en`, `screen`, `session`, `newxos`, `vpn of`, `notes`, `/tmp`

## What each case guards against

- `?` / `? ` — backends backend should show all children by default (discoverable), not filter by score when query is empty
- `?au` — discoverable backends should still filter when search text follows the prefix
- `zen` — adding characters shouldn't cause jarring reordering of the top result
- `zen ` (with trailing space) — whitespace after a prefix shouldn't collapse or drop the group
- `zen priv` — when one child clearly beats the parent, show it at top level; irrelevant partial matches (`zen browser`) must not appear as top results (that case broke when partial-match boosting leaked unrelated results)
- `zen new` — when multiple children are equally relevant, keep them nested under the parent; don't surface unrelated results that happen to match a substring (broke when a substring boost pulled in a flake result)
- `zen win` — action keywords should route to the correct action type, not fall through to general search
- `wifi` / `wifi on` / `wifi off` / `wifi toggle` — action state queries should resolve to the matching action; typing extra tokens shouldn't demote the action result
- `wo` / `wt` — two-letter acronym matching should select the intended action, not a partial match of something else (broke when short-token scoring was too aggressive)
- `:` — prefix gate should activate desktop-action mode, not leak to other backends
- `:wifi` / `:wifi on` — gated queries should scope to the gated namespace, not surface ungated results
- `@apps` — app gate should scope to desktop apps, not fall back to general search
- `@web nix` / `web nix` — explicit web mode should pass the raw query to the default browser, not construct engine-specific URLs
- `web !gh nix` — browser bang shortcuts should remain browser-owned by passing `!gh nix` to the default browser search engine
- `db wifi` / `dashboard wifi` — tab backend should activate on keyword; the same keyword typed with or without the tab prefix should produce consistent results
- `au` / `aud` / `audi` / `audio` — progressive typing should not cause jumpy reordering of the top result; the user should see a stable selection as they type (broke when short fuzzy matches from other backends intermittently outscored the correct result)
- `session` — session/power actions should appear as a group, not scattered as individual flat results
- `newxos` — flake/project results should show as a nested group with children, not collapsed into a single flat row
- `notes` — file results should not activate on ambiguous substring matching (broke when notes matched file backends and produced irrelevant file rows)
- `/tmp` — file backend should activate on path-like queries

## Source owners

- Engine and pipeline orchestration: `configs/quickshell/launcher/logic/Engine.qml`
- Tokenization and normalized node construction: `configs/quickshell/launcher/logic/Tokenize.qml`
- Indexing and candidate collection: `configs/quickshell/launcher/logic/IndexBuilder.qml`
- Evidence scoring and field matching: `configs/quickshell/launcher/logic/Evidence.qml`
- Evaluation tree construction and inherit policies: `configs/quickshell/launcher/logic/Evaluate.qml`
- Presentation decisions and group display: `configs/quickshell/launcher/policies/presentation/PresentationPolicy.qml`, `PresentationPresets.qml`
- Shaping and row generation: `configs/quickshell/launcher/logic/ResultShaping.qml` + `configs/quickshell/launcher/logic/RenderedRows.qml`
- Row post-processing and sorting: `configs/quickshell/launcher/logic/Rows.qml`
- Policy registry: `configs/quickshell/launcher/logic/CompositeSearchPolicyRegistry.js`, `configs/quickshell/launcher/PolicyRegistry.qml`
- Policy chaining and aggregation: `configs/quickshell/launcher/logic/PolicyChain.qml` (includes `lookupPolicy(registry, spec)` helper for normalized spec-aware lookups)
- Pipeline model/utility modules: `configs/quickshell/launcher/logic/ScoreBundle.qml`, `ResultShaping.qml`, `PresentationContext.qml`, `RenderedRows.qml`, `PolicySpec.qml`
- Current gaps: TokenFlowDecision not implemented; ActionPolicy not extracted; PolicySpec parameterized semantics still incremental
- Routing tree: `configs/quickshell/launcher/logic/RoutingTree.js`
