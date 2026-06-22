---
name: newxos-nix-module
description: Use when changing Nix modules, Home Manager modules, flake inputs, perSystem outputs, wrappers, packages, apps, checks, dev shells, or flake-file declarations in newxos.
---

# Newxos Nix Module

## Core Rule

All flake behavior changes go in `modules/`. Never edit generated `flake.nix` directly.

## Inspect First

- `AGENTS.md` and `docs/agent-index.md`
- `docs/architecture.md` — module layout, dendritic pattern, scope rules
- `docs/pitfalls.md` — recurring Nix scope mistakes
- Nearest existing module in `modules/` for pattern matching

## Ownership Map

| Path | Owns |
|------|------|
| `modules/core/` | Flake bootstrap, global inputs, dendritic activation |
| `modules/common/` | Shared NixOS modules (audio, locale, networking, SOPS) |
| `modules/dev/` | Dev tools, Neovim, OpenCode, git hooks |
| `modules/desktop/` | Desktop session, wrappers |
| `modules/hosts/<name>/` | Per-machine NixOS configuration |
| `modules/users/<name>/` | Per-user Home Manager configuration |
| `modules/theming/` | Stylix palette, generated theme fragments |
| `modules/desktop/wrappers/` | nix-wrapper-modules wrapper definitions |
| `modules/installation/` | Installer media |
| `modules/network/` | Network services |
| `modules/socials/` | Browser and comms apps |
| `modules/gaming/` | Gaming modules |

## Scope Rules

| Scope | Access |
|-------|--------|
| Top-level flake-parts | `inputs` (plain) |
| `perSystem` | `inputs'`, `self'`, `withSystem` |
| NixOS/HM module | `pkgs`, `config`, `lib`, `modulesPath` |

## Change Routing

| Symptom | Edit |
|---------|------|
| New module not found | Check file is valid `.nix` under `modules/` (import-tree auto-imports) |
| Flake output missing | Declare output in owning `modules/` file, then `write-flake` |
| `inputs'`/`self'` error in top-level | Move to `perSystem` block |
| NixOS-only args missing | Export as real NixOS module function, use `withSystem` |
| `imports` inside `lib.mkMerge` fails | Keep `imports` at module top level, put conditions under `config = lib.mkMerge [...]` |
| Program needs opinionated config | Check `modules/desktop/wrappers/` for existing wrapper |
| Stale `flake.nix` after declaration change | Run `write-flake` before `flake show`/`flake check` |

## Procedure

1. Locate owning module or nearest similar feature.
2. Make the smallest source change in `modules/`.
3. If flake-file declarations changed: `nix run "path:$PWD#write-flake"`.
4. If outputs changed: `nix flake show "path:$PWD"`.
5. Run formatting and narrowest checks.

## Validation

| Trigger | Command |
|---------|---------|
| Declarations changed | `nix run "path:$PWD#write-flake"` |
| Outputs changed | `nix flake show "path:$PWD"` |
| Handoff | `repo-gate nix` or `repo-gate all` |

## Do Not

- Edit `flake.nix` directly — it is generated.
- Put `imports` inside `lib.mkMerge`.
- Duplicate exact package lists or option values in docs.
- Add backward-compat shims or migration wrappers without concrete persisted/shipped/external need.
- Parameterize exported NixOS modules with ad hoc outer args.

## Done Criteria

- Change is in `modules/`, not `flake.nix`.
- `write-flake` and `flake show` pass if declarations or outputs changed.
- Formatting applied (`nix run "path:$PWD#fmt"`).
- Existing behavior preserved or explained why not.
