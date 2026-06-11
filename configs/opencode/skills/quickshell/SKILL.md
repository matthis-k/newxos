---
name: quickshell
description: Use for repo-specific QuickShell/QML work in this flake. Routes agents to local contracts, architecture, source, and Qt docs instead of copied upstream library notes.
---

# QuickShell Project Routing

## Core Rule

Always check repo-owned contracts, architecture, and source before consulting upstream QuickShell docs or generic QML examples. Repo policy overrides upstream defaults.

## Source Order

For QuickShell/QML work, consult in this order:

1. Basic Memory → project knowledge
2. `docs/agent-index.md` → topic routing
3. `docs/architecture.md` → launcher pipeline, wrapper behavior
4. `docs/contracts/quickshell-design.md` → visual style, spacing, QML conventions
5. `docs/pitfalls.md` → known Quickshell bugs and workarounds
6. Source files in `configs/quickshell/` → actual behavior
7. Qt Documentation MCP → Qt/QML framework API
8. Context7 → external library docs not covered by Qt or local source

## Ownership Map

| Concern | Owner |
|---------|-------|
| Visual style, spacing, animation | `docs/contracts/quickshell-design.md` |
| Launcher pipeline, IPC | `docs/architecture.md` |
| Known bugs and workarounds | `docs/pitfalls.md` |
| QML source | `configs/quickshell/` |
| Wrapper, dev mode, newshell binary | `modules/desktop/wrappers/quickshell.nix` |
| Theming | `modules/theming/` |
| Qt/QML framework API | Qt Documentation MCP |
| External library docs | Context7 |

## Do Not

- Treat generic QuickShell examples as project policy.
- Put backend references, live QML objects, or evaluated trees in result rows.
- Recompute scoring in UI delegates.
- Duplicate wrapper-generated config into handwritten QML.
- Use `Qt.application.environment` for live env checks — use `Quickshell.env("VAR")` instead.

## Done Criteria

- Most relevant repo doc consulted before upstream sources.
- No upstream-only assumptions without local verification.
