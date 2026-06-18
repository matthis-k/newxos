# Agent knowledge index

## When starting a task
- `AGENTS.md` — operating instructions, commands, coding rules
- `docs/agent-index.md` — task-specific routes to deeper docs

## When changing Nix modules
- `docs/architecture.md` — dendritic layout, placement rules, flake-file, import-tree
- `docs/adr/` — relevant architecture decisions
- `docs/pitfalls.md` — common Nix scope mistakes

## When changing Quickshell QML
- `docs/contracts/quickshell-design.md` — visual style, spacing, animation contracts
- `docs/pitfalls.md` — known Quickshell bugs and workarounds
- `docs/playbooks/dev-specialization.md` — live config reloading
- `docs/architecture.md` — launcher architecture overview

## When changing Hyprland keymaps
- `docs/contracts/hyprland-keymap.md` — key-cycle resolver contract, DSL shape, backend limits
- Source: `configs/hypr/keybinds.lua`, `configs/hypr/keymap/`
- Test: `lua configs/hypr/keymap/tests.lua`

## When touching launcher search
- `docs/architecture.md` — launcher architecture (pipeline, DTO boundary, prefix gating)
- `docs/contracts/quickshell-design.md` — anti-patterns for row data and backends
- `docs/playbooks/launcher-sanity-check.md` — ranking intent and IPC debugging guidance
- `docs/pitfalls.md` — historical launcher bugs

## When touching secrets or auth
- `AGENTS.md` — safety rules, data care
- `docs/pitfalls.md` — secret-related gotchas
- Source: `modules/common/sops.nix`, `modules/dev/opencode.nix`

## When adding a new host or user
- `docs/architecture.md` — host-and-user layout pattern
- Source: existing host in `modules/hosts/` and user in `modules/users/`

## When changing theming
- `docs/architecture.md` — Stylix integration, palette flow
- `docs/pitfalls.md` — theming-specific gotchas
- Source: `modules/theming/`

## When maintaining the knowledge base
- `docs/playbooks/maintain-docs.md` — target structure, classification rules, filtering rules, relevance standard

## When using skills
- `configs/opencode/skills/newxos-nix-module/` — Nix modules, flake outputs, wrappers, packages, checks, dev shells
- `configs/opencode/skills/quickshell-qml-component/` — repo-specific QuickShell QML components, services, panels, layout, animation
- `configs/opencode/skills/launcher-search-change/` — launcher backends, scoring, evidence, DTOs, prefix gating, async search
- `configs/opencode/skills/repo-verification/` — check selection before handoff
- `configs/opencode/skills/knowledge-maintenance/` — docs, ADRs, pitfalls, contracts, playbooks, memory reindexing
- `configs/opencode/skills/secrets-and-auth/` — secrets, sops-nix, auth tokens, MCP/provider auth
- `configs/opencode/skills/context7-library-docs/` — current external library/API docs not covered by NixOS or Qt tooling
- `configs/opencode/skills/quickshell/` — repo-specific QuickShell/QML routing
- Upstream Qt skills — Qt/QML/C++ docs, review, profiling, and UI design tasks

## When needing external library docs
- Context7 MCP — external library/framework/package docs only
- NixOS MCP — NixOS, Home Manager, Darwin, Nixvim, nixpkgs, and flake docs
- Qt Documentation MCP — Qt and QML framework docs
- Basic Memory and `docs/` — repo-specific behavior and decisions

## When debugging
- `docs/pitfalls.md` — known issues and their root causes
- `docs/architecture.md` — scope boundaries, module boundaries
