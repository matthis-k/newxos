# home-manager

Home Manager handles user-level configuration.

## What It Does Here

- Provides the Home Manager flake module imported from `modules/home-manager.nix`.
- Exposes shared `flake.modules.homeManager.*` modules that hosts or standalone configs can reuse.
- Owns user-level packages and app config placement.

## Basics

- This repo enables `useGlobalPkgs = true` and `useUserPackages = true` for NixOS integration.
- User-specific config belongs under `modules/users/<name>/`.
- Shared user-facing features live in shared `flake.modules.homeManager.*` modules.
- Related reading: [Host And User Layout](../patterns/host-and-user-layout.md), [Wrapped Programs And Generated Config](../patterns/wrapped-programs.md).

## Short Example

```nix
flake.modules.homeManager.neovim =
  { pkgs, ... }:
  {
    home.packages = withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: [
      self'.packages.nvim
      self'.packages.nvimdev
    ]);
  };
```

## Helpful Docs

- Main docs: `https://nix-community.github.io/home-manager/`

## Known Quirks Here

- Prefer explicit shared module imports when the repo owns the integration pattern.
- Stylix Home Manager wiring is explicit here. Do not rely on automatic HM import from Stylix.
- When user config is tightly coupled to system config, co-locating small pieces is fine. Do not force a split just for its own sake.
