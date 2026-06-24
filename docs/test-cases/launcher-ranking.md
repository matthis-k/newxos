# Launcher ranking intent

> **Canonical behavior cases**: JSON case files under `tests/launcher/cases/`. Run with `repo-gate launcher`.

Probes are derived from canonical cases — do not maintain separate jq case files.

## Ranking rationale (case-backed)

Each JSON case in `tests/launcher/cases/` guards a specific ranking aspect. This document explains the intent behind those cases — not the expectations themselves:

- Backend discoverability: empty or prefix-triggered queries should show backends' children without score filtering
- Direct match stability: as the user types, the top result should remain stable when the query is a progressive refinement of the same intent
- Action state resolution: `wifi on` / `wifi off` / `wifi toggle` should resolve to matching action states; extra tokens should not demote
- Short acronym matching: two-letter queries (`wo`, `wt`) should select the intended action, not a partial match
- Prefix gating: gated queries (`:` for actions, `@apps` for desktop, `@web` for web) should stay in their namespace
- Group expansion: trailing space should expand a group to show direct children
- Child takeover: when one child clearly beats the parent for a query, show it at top level
- Progressive typing stability: adding characters should not cause jarring reordering of the top result
- Session/power grouping: related actions should appear as a group, not scattered
- Ambient vs gated: short unqualified tokens should not surface deeply nested items that require parent context
- File backend activation: path-like queries (`/tmp`) should activate file search; ambiguous substrings should not

## Broad source owners

| Area | Path |
|------|------|
| Pipeline logic | `configs/newshell/launcher/logic/` |
| Controllers | `configs/newshell/launcher/controllers/` |
| Backends | `configs/newshell/launcher/backends/` |
| Policies | `configs/newshell/launcher/policies/` |
| Canonical cases | `tests/launcher/cases/` |
