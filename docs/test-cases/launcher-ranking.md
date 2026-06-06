# Launcher ranking expectations

Use `newshell ipc call query search '<query>'` after `systemctl --user restart newshell` to verify results. Source: `configs/quickshell/launcher/logic/CompositeSearchFlatten.js`.

## Core checklist

Run these queries after any launcher search change:

`zen`, `zen `, `zen priv`, `zen win`, `zen browser`, `zen new`, `wifi`, `wifi `, `wifi on`, `wifi off`, `wifi toggle`, `toggle wifi`, `wo`, `wt`, `:`, `:wifi`, `:wifi `, `:wifi on`, `:db wifi`, `@apps`, `@apps zen`, `@apps wifi`, `db wifi`, `dashboard wifi`, `au`, `aud`, `audi`, `audio`, `en`, `screen`, `session`, `newxos`, `vpn of`, `notes`, `/tmp`

## What each case guards against

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
- `db wifi` / `dashboard wifi` — tab backend should activate on keyword; the same keyword typed with or without the tab prefix should produce consistent results
- `au` / `aud` / `audi` / `audio` — progressive typing should not cause jumpy reordering of the top result; the user should see a stable selection as they type (broke when short fuzzy matches from other backends intermittently outscored the correct result)
- `session` — session/power actions should appear as a group, not scattered as individual flat results
- `newxos` — flake/project results should show as a nested group with children, not collapsed into a single flat row
- `notes` — file results should not activate on ambiguous substring matching (broke when notes matched file backends and produced irrelevant file rows)
- `/tmp` — file backend should activate on path-like queries

## Source owners

- Flattening and row generation: `configs/quickshell/launcher/logic/CompositeSearchFlatten.js`
- Scoring and evidence: `configs/quickshell/launcher/logic/CompositeSearchEvaluate.js`, `configs/quickshell/launcher/logic/CompositeSearchEvidence.js`
- Prefix parsing and backend participation: `configs/quickshell/launcher/logic/CompositeSearchPipeline.js`, `configs/quickshell/launcher/logic/QueryParsing.js`
