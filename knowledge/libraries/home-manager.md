---
title: home-manager
type: note
permalink: newxos/libraries/home-manager
---

# home-manager

Home Manager handles user-level configuration.

## Observations

- [fact] Provides the Home Manager flake module imported from `modules/common/home-manager.nix`
- [technique] Shared Home Manager integration is owned by `modules/common/home-manager.nix`
- [decision] Prefer explicit shared module imports when the repo owns the integration pattern
- [fact] Stylix Home Manager wiring is explicit; do not rely on automatic HM import from Stylix

## Relations

- relates_to [[Host And User Layout]]
- relates_to [[Wrapped Programs And Generated Config]]

## What It Does Here

- Provides the Home Manager flake module imported from `modules/common/home-manager.nix`.
- Exposes shared `flake.modules.homeManager.*` modules that hosts or standalone configs can reuse.
- Owns user-level packages and app config placement.

## Basics

- Read `modules/common/home-manager.nix` for exact NixOS integration options.
- User-specific config belongs under `modules/users/<name>/`.
- Shared user-facing features live in shared `flake.modules.homeManager.*` modules.
- Related reading: [[Host And User Layout]], [[Wrapped Programs And Generated Config]].

## Helpful Docs

- Main docs: `https://nix-community.github.io/home-manager/`

## Known Quirks

- Prefer explicit shared module imports when the repo owns the integration pattern.
- Stylix Home Manager wiring is explicit here. Do not rely on automatic HM import from Stylix.
- When user config is tightly coupled to system config, co-locating small pieces is fine. Do not force a split just for its own sake.
