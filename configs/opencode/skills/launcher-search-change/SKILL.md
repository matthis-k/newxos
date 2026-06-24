---
name: launcher-search-change
description: Use when changing launcher backends, tokenization, evidence, scoring, flattening, row DTOs, prefix gating, async search, or launcher result rendering.
---

# Launcher Search Change

## Core Rule

Launcher behavior changes should be policy-driven. Backend data must cross the DTO boundary as plain serializable objects. UI delegates render, they do not compute.

Decision pipeline: `Pipeline stage → decision kind → decider → policy votes → final decision`. Full contract: `docs/contracts/launcher-policy-decisions.md`.

## Inspect First

- `docs/contracts/launcher-policy-decisions.md`
- `docs/contracts/quickshell-design.md` — anti-patterns section
- `docs/pitfalls.md` — launcher pitfalls
- `docs/test-cases/launcher-ranking.md`
- `docs/newshell/launcher-testing.md`
- `configs/opencode/skills/newshell-debugging/SKILL.md`
- Owning backend or logic file in `configs/newshell/launcher/`

## Ownership Map

| Path | Owns |
|------|------|
| `launcher/logic/` | Pipeline modules (evidence, scoring, shaping, row DTOs, policy, routing) |
| `launcher/controllers/` | Session lifecycle, navigation, activation, debug endpoints |
| `launcher/backends/` | Backend DTOs and search |
| `launcher/policies/` | Policy implementations |
| `launcher/delegates/` | UI delegates |
| `launcher/Launcher.qml` | IPC boundary |

## Change Routing

| Symptom | Edit |
|---------|------|
| Matching wrong or incomplete | Edit evidence/searchable-field config in backend or PolicyChain |
| Ranking wrong | Edit scoring/boost policy |
| Display wrong | Edit row DTO (`RenderedRows.qml`), presentation context, or delegate |
| Source data wrong | Edit backend DTO construction |
| Backend not participating | Check prefix/routing registration |
| Children missing or leaking after shaping | Check child contract in `Engine.qml` and `ResultShaping.qml` |
| Web fallback appearing with visible results | Check web fallback gating |
| Row DTO field missing or wrong type | Update `RenderedRows.qml` and delegates |

## IPC Commands

```bash
newshell ipc call query pipeline '<query>'    # Universal debug
```

For full debug flow: `configs/opencode/skills/newshell-debugging/SKILL.md`.

## Do Not

- Keep whole evaluated trees in result rows.
- Treat permission alone as evidence of relevance.
- Prewarm backends whose source model populates asynchronously.
- Let web fallback compete when non-web visible rows exist.
- Put ranking or action-selection logic in UI delegates.
- Serialize raw QML objects in IPC responses.
- Overwrite evaluated policy trace entries.

## Done Criteria

- Smallest correct owner changed.
- Backend DTOs are plain serializable objects.
- Prefix gating unchanged unless intended.
- Web fallback behavior preserved.
- Ranking intent verified with representative queries.
- No raw QML objects in IPC responses.
