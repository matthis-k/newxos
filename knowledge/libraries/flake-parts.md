# flake-parts

`flake-parts` is the core module system for this flake.

## What It Does Here

- Defines the top-level schema for `imports`, `perSystem`, and `flake`.
- Lets the repo export reusable modules under `flake.modules.*`.
- Gives the repo `withSystem`, `inputs'`, and `self'` for clean per-system access.
- Works together with the dendritic layout so most behavior lives in small modules under `modules/`.

## Basics

- Use plain `inputs` for global flake wiring.
- Use `perSystem` for system-specific packages, apps, checks, and dev shells.
- Use `inputs'` and `self'` inside `perSystem` instead of manually indexing `.${system}` when a proper per-system view exists.
- Use `withSystem` when a top-level reusable module needs a per-system package.
- Related reading: [Scope Boundaries And Per-System Access](../patterns/per-system-scopes.md), [Dendritic Feature Modules](../patterns/dendritic-modules.md).

## Short Examples

```nix
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
}
```

```nix
perSystem = { inputs', pkgs, ... }: {
  packages.example = pkgs.writeShellScriptBin "example" ''
    exec ${inputs'.some-input.packages.default}/bin/example "$@"
  '';
};
```

```nix
flake.modules.homeManager.example =
  { pkgs, ... }:
  {
    home.packages = withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: [
      self'.packages.example
    ]);
  };
```

## Helpful Docs

- Main docs: `https://flake.parts/`
- Option reference: `https://flake.parts/options/flake-parts.html`
- Module arguments: `https://flake.parts/module-arguments.html`
- Exported module docs: `https://flake.parts/options/flake-parts-modules.html`
- Reusable module guide: `https://flake.parts/dogfood-a-reusable-module.html`

## Known Quirks Here

- Do not reach for `self.packages.${system}` from a top-level reusable module when `withSystem` and `self'` are the right fit.
- Do not request NixOS-only module args like `modulesPath` from the outer flake-parts file function.
- Do not fake reusable NixOS module parameters with outer default args unless you also pass them through real module args.
- If something feels like a scope problem, it usually is.
- Related issues: [2026-04-27: `modulesPath` missing from outer flake-parts module args](../encountered_issues.md#2026-04-27-modulespath-missing-from-outer-flake-parts-module-args), [2026-04-27: reaching for `self.packages.${system}` instead of `withSystem` and `self'`](../encountered_issues.md#2026-04-27-reaching-for-selfpackagessystem-instead-of-withsystem-and-self), [2026-04-28: defaulted outer module args still require `_module.args` when reused as NixOS modules](../encountered_issues.md#2026-04-28-defaulted-outer-module-args-still-require-_moduleargs-when-reused-as-nixos-modules)
