---
title: nh-nom
type: note
permalink: newxos/libraries/nh-nom
---

# nh And nom

This repo uses `nh` and `nix-output-monitor` through repo-owned `newxos` wrapper package.

## What It Does Here

- `newxos os ...` calls `nh os ...` for NixOS rebuild flows.
- `newxos home ...` calls `nh home ...` for Home Manager build and switch flows.
- `newxos clean` defaults to `nh clean all --keep 1 --keep-since 0h`, and forwards any extra flags to `nh clean all` when you want a different retention policy.
- `newxos flake build/check/run ...` uses `nom` so direct `nix` operations still get rich build output.
- `newxos` defaults to `path:$NEWXOS_FLAKE` so local unadded changes are visible during eval and builds.
- `--git-only` switches back to git flake semantics when you want repo-visible tree only.

## Basics

- Home Manager exports `NEWXOS_FLAKE=$HOME/newxos` and installs `newxos` into user profile.
- NixOS host module exports `NEWXOS_HOST=$HOSTNAME` through `environment.sessionVariables`.
- Fish completion comes from package payload under `share/fish/vendor_completions.d/`.
- Host completion is repo-driven by reading `flake.nixosConfigurations.*` declarations from `modules/`.
- Home config completion is repo-driven by reading `flake.homeConfigurations.*` declarations from `modules/`.
- Related reading: [home-manager](home-manager.md), [Workflow](../workflow.md).

## Helpful Docs

- `nh`: `https://github.com/nix-community/nh`
- `nix-output-monitor`: `https://github.com/maralorn/nix-output-monitor`

## Known Quirks Here

- `newxos flake show` stays plain `nix flake show`; there is no useful `nom` wrapper for that output.
- `newxos os ...` and `newxos flake build ...` can omit host only when `NEWXOS_HOST` is present in shell environment.
- `newxos flake run` targets runnable flake attrs like package or app names, not NixOS host names.
