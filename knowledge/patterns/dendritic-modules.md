---
title: dendritic-modules
type: note
permalink: newxos/patterns/dendritic-modules
---

# Dendritic Feature Modules

Keep the root flake thin and spread behavior across small modules near the owning feature.

## Observations

- [fact] `modules/` is the real source of truth
- [decision] Organize by concern or feature, not one central registry file
- [technique] Feature modules can expose inputs, reusable `flake.modules.*` modules, `perSystem` packages, and concrete outputs from one nearby place
- [fact] Inside `perSystem`, use `self'` for system-qualified outputs; top-level `self` is the source tree and top-level flake outputs

## Relations

- relates_to [[Flake Structure]]
- relates_to [[flake-file]]
- relates_to [[flake-parts]]

## What It Means Here

The dendritic pattern organizes configuration by feature or concern rather than only by target system. A feature module may contribute:

- NixOS configuration
- Home Manager configuration
- flake inputs
- packages, apps, overlays
- development shells
- generated flake-file declarations

Concrete rules:

- `modules/` is the real source of truth.
- Feature modules can expose inputs, reusable `flake.modules.*` modules, `perSystem` packages, and concrete outputs from one nearby place.
- Organize by concern or feature, not one central registry file.
- Related reading: [[Flake Structure]], [[flake-file]], [[flake-parts]].

## Source Pointers

- Dendritic layout activation lives in `modules/core/`.
- Feature modules live under `modules/` near the owning concern.
- Exact examples belong in source modules, not copied into memory.

## Practical Rules

- Keep shared cross-host behavior in shared modules near the top of `modules/`.
- Keep host-local files in `modules/hosts/<hostname>/`.
- Keep user-local files in `modules/users/<name>/`.
- Split a feature into multiple nearby files only when it helps readability.
- Do not move logic back into the generated root flake.

## Common Pitfalls

- Do not edit generated `flake.nix` by hand. Change module source, then run `nix run "path:$PWD#write-flake"` if you changed `flake-file` declarations.
- Inside `perSystem`, use `self'` for system-qualified outputs. Top-level `self` is the source tree and top-level flake outputs.
- Name module args explicitly when you need them. If a module uses `pkgs`, `self'`, or `system`, request them in the function arg set.
- If one file starts collecting unrelated behavior, split it into another nearby module instead of rebuilding a central registry.
