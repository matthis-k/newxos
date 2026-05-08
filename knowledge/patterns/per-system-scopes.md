# Scope Boundaries And Per-System Access

Most hard Nix mistakes in this repo are scope mistakes.

## The Main Scopes

- Top-level flake module scope: `imports`, `flake`, global input wiring, and reusable module definitions.
- `perSystem` scope: packages, apps, checks, dev shells, and system-specific access through `inputs'` and `self'`.
- NixOS or Home Manager module scope: real module options like `pkgs`, `config`, `lib`, and NixOS-only args such as `modulesPath`.
- Related reading: [flake-parts](../libraries/flake-parts.md).

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

## Practical Rules

- Use plain `inputs` for global wiring.
- Use `inputs'` and `self'` inside `perSystem`.
- Use `withSystem` to re-enter per-system scope from a top-level reusable module.
- If a reusable `flake.modules.nixos.*` value needs `modulesPath`, `config`, or similar, make the value itself a NixOS module function.
- Do not parameterize exported NixOS modules with ad hoc outer args unless you also pass them through real module args.

## Known Quirks

- The repo has repeatedly hit `modulesPath`, `self'`, and outer default-arg traps.
- Related issues: [2026-04-27: `modulesPath` missing from outer flake-parts module args](../encountered_issues.md#2026-04-27-modulespath-missing-from-outer-flake-parts-module-args), [2026-04-27: reaching for `self.packages.${system}` instead of `withSystem` and `self'`](../encountered_issues.md#2026-04-27-reaching-for-selfpackagessystem-instead-of-withsystem-and-self), [2026-04-28: defaulted outer module args still require `_module.args` when reused as NixOS modules](../encountered_issues.md#2026-04-28-defaulted-outer-module-args-still-require-_moduleargs-when-reused-as-nixos-modules)
