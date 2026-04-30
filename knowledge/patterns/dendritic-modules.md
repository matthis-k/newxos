# Dendritic Feature Modules

This repo follows the dendritic pattern: keep the root flake thin and spread behavior across small modules near the feature that owns it.

## What It Means Here

- `modules/` is the real source of truth.
- Feature modules can expose inputs, reusable `flake.modules.*` modules, `perSystem` packages, and concrete outputs from one nearby place.
- Prefer organizing by concern or feature, not one giant central registry file.
- Related reading: [Flake Structure](../flake-structure.md), [flake-file](../libraries/flake-file.md), [flake-parts](../libraries/flake-parts.md).

## Short Example

```nix
{ inputs, ... }:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ inputs.home-manager.flakeModules.home-manager ];
}
```

## Practical Rules

- Keep shared cross-host behavior in shared modules near the top of `modules/`.
- Keep host-local files in `modules/hosts/<hostname>/`.
- Keep user-local files in `modules/users/<name>/`.
- Split a feature into multiple nearby files only when that helps readability.
- Do not move logic back into the generated root flake.
