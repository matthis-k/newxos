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

## Minimal Starter Shape

This section is the doc replacement for the old `dendritic-simple-module` template.

- `modules/dendritic.nix`: turn on the dendritic `flake-file` layout.
- `modules/example-message.nix`: keep one small concern in one nearby `flake-parts` module.

```nix
# modules/dendritic.nix
{ inputs, ... }:
{
  imports = [ inputs.flake-file.flakeModules.dendritic ];
}
```

```nix
# modules/example-message.nix
{ ... }:
{
  perSystem = { pkgs, self', ... }: {
    packages.example-message = pkgs.writeShellScriptBin "example-message" ''
      printf '%s\n' "hello from a small dendritic module"
    '';

    apps.example-message.program = "${self'.packages.example-message}/bin/example-message";
  };
}
```

## Practical Rules

- Keep shared cross-host behavior in shared modules near the top of `modules/`.
- Keep host-local files in `modules/hosts/<hostname>/`.
- Keep user-local files in `modules/users/<name>/`.
- Split a feature into multiple nearby files only when that helps readability.
- Do not move logic back into the generated root flake.

## Common Pitfalls

- Do not edit generated `flake.nix` by hand. Change module source, then run `nix run "path:$PWD#write-flake"` when you changed `flake-file` declarations.
- Inside `perSystem`, use `self'` for system-qualified outputs. Top-level `self` is the source tree and top-level flake outputs.
- Name module args explicitly when you need them. If a module uses `pkgs`, `self'`, or `system`, request them in the function arg set.
- If one file starts collecting unrelated behavior, split it into another nearby module instead of rebuilding a central registry.
