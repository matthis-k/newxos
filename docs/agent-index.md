# Agent knowledge index

## When starting a task
- `AGENTS.md` — operating instructions, commands, coding rules
- `docs/architecture.md` — repo structure, module layout, scope rules

## When changing Nix modules
- `docs/architecture.md` — dendritic layout, placement rules, flake-file, import-tree
- `docs/adr/` — relevant architecture decisions
- `docs/pitfalls.md` — common Nix scope mistakes

## When changing Quickshell QML
- `docs/contracts/quickshell-design.md` — visual style, spacing, animation contracts
- `docs/pitfalls.md` — known Quickshell bugs and workarounds
- `docs/playbooks/dev-specialization.md` — live config reloading
- `docs/architecture.md` — launcher architecture overview

## When touching launcher search
- `docs/architecture.md` — launcher architecture (pipeline, DTO boundary, prefix gating)
- `docs/contracts/quickshell-design.md` — anti-patterns for row data and backends
- `docs/test-cases/launcher-ranking.md` — ranking regression expectations
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

## When debugging
- `docs/pitfalls.md` — known issues and their root causes
- `docs/architecture.md` — scope boundaries, module boundaries
