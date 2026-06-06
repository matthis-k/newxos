---
name: quickshell
description: Use for repo-specific QuickShell/QML work in this flake. Routes agents to local contracts, architecture, source, and Qt docs instead of copied upstream library notes.
---

# QuickShell Project Routing

Use this skill when editing, reviewing, or debugging `configs/quickshell/` or related wrapper modules.

## Source Order

- Project behavior: Basic Memory -> `docs/agent-index.md` -> local docs -> source inspection.
- Visual and interaction rules: `docs/contracts/quickshell-design.md`.
- Launcher pipeline rules: `docs/architecture.md`.
- Known project bugs and workarounds: `docs/pitfalls.md`.
- Qt/QML framework API details: Qt Documentation MCP.
- External library docs not covered by Qt or local source: Context7.

## Do Not

- Treat generic QuickShell examples as project policy.
- Put backend references, live QML objects, or evaluated trees in launcher result rows.
- Recompute scoring in UI delegates.
- Duplicate wrapper-generated config into handwritten QML.

## Verify

- Prefer the narrowest runnable check first.
- Use `nix run "path:$PWD#repo-gate"` for handoff when practical.
