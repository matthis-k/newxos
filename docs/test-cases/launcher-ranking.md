# Launcher ranking expectations

> **Canonical behavior cases**: JSON case files under `tests/launcher/cases/`. These are the executable source of truth for query expectations. Run with `repo-gate newshell-cases` or during `repo-gate newshell`.

Use `newshell ipc call query pipeline '<query>'` or `newshell-launcher-test probe tests/launcher/cases --filter '<query>' --run` to verify results. Plain `pipeline` calls are compact/visible-only overviews; use `newshell ipc call query pipeline '{"query":"ze","focusNodeId":"desktop:apps:zen_beta","details":["rows","phases"]}'` for focused hidden evaluation of one node family with selected detail sections. Source: `configs/newshell/launcher/logic/` (QML pipeline modules).

Probes are derived from canonical cases — do not maintain separate jq case files. See `docs/newshell/launcher-testing.md` for probe derivation.

## What each case guards against

- `?` / `? ` — backends backend should show all children by default (discoverable), not filter by score when query is empty
- `?au` — discoverable backends should still filter when search text follows the prefix
- `v` — inert empty containers must not appear above actionable visual matches such as VPN
- `new` — Newxos should win as the direct parent/group match; desktop app actions such as Zen's new-window actions may appear below it but are penalized for skipping their app root
- `zen` — adding characters shouldn't cause jarring reordering of the top result; the desktop entry should remain the selectable default action and child actions stay hidden until the query asks to explore or names child intent
- `zen ` (with trailing space) — whitespace after a prefix should show the app as a group with all direct child actions while keeping parent and children selectable
- `zen priv` — when one child clearly beats the parent, show it at top level; irrelevant partial matches (`zen browser`) must not appear as top results (that case broke when partial-match boosting leaked unrelated results)
- `zen new` — when multiple children are equally relevant, keep them nested under the parent, with parent activation suppressed; don't surface unrelated results that happen to match a substring (broke when a substring boost pulled in a flake result)
- `zen win` — action keywords should route to the correct action type, not fall through to general search
- `ze` with focused `desktop:apps:zen_beta` pipeline debug — targeted hidden evaluation should show only the Zen entry family, not every hidden calculation for every desktop entry
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
- `vpn` — VPN should show as a switch row without expanding destination children
- `vpn ` — VPN should become an expanded group with all direct destinations visible; destination groups sort before countries, and the root remains selectable
- `vpn ger` — VPN destinations should filter by the extra term, and the VPN root should not be selectable while filtered children are better answers
- `vpn germany` — a single exact destination match should take over the VPN root
- `ger` / `alg` / `bel` / `swe` — short country prefixes should not surface VPN rows from ambient search because skipping the VPN parent is too weak
- `germany` / `algeria` / `belgium` / `sweden` — exact country names are strong enough to surface the matching VPN destination from ambient search
- `net` / `networking` — Networking should show as an expanded exploration group with direct controls such as Wi-Fi, VPN, and Bluetooth; long child lists under those controls stay hidden unless that child node is directly explored
- `notes` — file results should not activate on ambiguous substring matching (broke when notes matched file backends and produced irrelevant file rows)
- `/tmp` — file backend should activate on path-like queries

## Source owners

- Engine and pipeline orchestration: `configs/newshell/launcher/logic/Engine.qml`
- Tokenization and normalized node construction: `configs/newshell/launcher/logic/Tokenize.qml`
- Indexing and candidate collection: `configs/newshell/launcher/logic/IndexBuilder.qml`
- Evidence scoring and field matching: `configs/newshell/launcher/logic/Evidence.qml`
- Evaluation tree construction and inherit policies: `configs/newshell/launcher/logic/Evaluate.qml`
- Presentation decisions and group display: `configs/newshell/launcher/policies/presentation/PresentationPolicy.qml`, `PresentationPresets.qml`
- Shaping, default action selection, and row generation: `configs/newshell/launcher/logic/ResultShaping.qml` + `ActionPolicy.qml` + `RenderedRows.qml`
- Row post-processing and sorting: `configs/newshell/launcher/logic/Rows.qml`
- Policy registry: `configs/newshell/launcher/logic/CompositeSearchPolicyRegistry.js`, `configs/newshell/launcher/PolicyRegistry.qml`
- Policy chaining and aggregation: `configs/newshell/launcher/logic/PolicyChain.qml` (includes `lookupPolicy(registry, spec)` helper for normalized spec-aware lookups)
- Pipeline model/utility modules: `configs/newshell/launcher/logic/ScoreBundle.qml`, `ResultShaping.qml`, `PresentationContext.qml`, `ActionPolicy.qml`, `RenderedRows.qml`, `PolicySpec.qml`
- Controller/session ownership: `configs/newshell/launcher/controllers/` for debounce/async, result navigation, activation, and debug endpoints; `LauncherController.qml` remains the public compatibility façade
- Current gaps: TokenFlowDecision not implemented; PolicySpec parameterized semantics still incremental
- Routing tree: `configs/newshell/launcher/logic/RoutingTree.js`
