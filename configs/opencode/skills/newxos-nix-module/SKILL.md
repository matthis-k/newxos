---
name: newxos-nix-module
description: Use when changing Nix modules, Home Manager modules, flake inputs, perSystem outputs, wrappers, packages, apps, checks, dev shells, or flake-file declarations in newxos.
---

# Newxos Nix Module Work

Use this skill for Nix changes that affect repo behavior or flake outputs.

## Inspect First

- Read `AGENTS.md` and `docs/agent-index.md`.
- For module layout and scope rules, read `docs/architecture.md`.
- For recurring mistakes, read `docs/pitfalls.md`.
- Inspect existing nearby modules before adding new structure.

## Rules

- Edit `modules/`, not generated `flake.nix`.
- Keep feature logic in the dendritic feature directory that owns it.
- Use plain `inputs` for top-level flake wiring.
- Use `inputs'` and `self'` only inside `perSystem`.
- Use `withSystem` when a reusable NixOS/Home Manager module needs per-system packages.
- Export reusable NixOS modules as real NixOS module functions when they need `config`, `pkgs`, or `modulesPath`.
- Do not put `imports` inside `lib.mkMerge`.
- Prefer existing wrappers in `modules/desktop/wrappers/` over raw packages.

## Procedure

1. Locate the owning module or nearest similar feature.
2. Make the smallest source change in `modules/` or nearby owned config.
3. If flake-file declarations changed, run `nix run "path:$PWD#write-flake"` before introspection.
4. If adding or changing outputs, run `nix flake show "path:$PWD"`.
5. Run formatting and the narrowest relevant checks.

## Checks

- Flake-file declaration changed: `nix run "path:$PWD#write-flake"`.
- Output added/changed: `nix flake show "path:$PWD"`.
- Handoff when practical: `nix run "path:$PWD#repo-gate"`.

## Do Not

- Manually edit `flake.nix`.
- Duplicate exact package lists or option values in docs.
- Add compatibility layers without a concrete persisted/shipped/external need.
