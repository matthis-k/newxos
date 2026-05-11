---
title: workflow-tooling
type: note
permalink: newxos/libraries/workflow-tooling
---

# Workflow Tooling

This repo uses `treefmt-nix` and `git-hooks.nix` for formatting and pre-commit workflow.

## What It Does Here

- `treefmt-nix` exposes the formatter behind `nix run "path:$PWD#fmt"`.
- `git-hooks.nix` installs and runs the managed pre-commit hook.
- The repo also exposes `repo-gate`, which runs `write-flake -> fmt -> flake check`.

## Basics

- Use `repo-gate` when you want the same broad flow as pre-commit.
- `packages.fmt` comes from the treefmt wrapper.
- The default dev shell comes from the pre-commit integration.
- Related reading: [Workflow](../workflow.md).

## Starter Workflow Module Shape

This replaces the old `dendritic-workflow-module` template.

- Keep extra flake inputs in one `flake-file` module.
- Keep workflow behavior in a separate module that imports upstream flake modules and defines helper packages.

```nix
# modules/workflow-inputs.nix
{ ... }:
{
  flake-file.inputs.git-hooks-nix = {
    url = "github:cachix/git-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

```nix
# modules/workflow.nix
{ inputs, lib, self, ... }:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = { config, pkgs, ... }:
    let
      repoGate = pkgs.writeShellScriptBin "repo-gate" ''
        set -euo pipefail
        ${pkgs.nix}/bin/nix run "path:$PWD#write-flake"
        ${config.treefmt.build.wrapper}/bin/treefmt
        ${pkgs.nix}/bin/nix flake check "path:$PWD"
      '';
    in {
      packages.fmt = config.treefmt.build.wrapper;
      packages.repo-gate = repoGate;
    };
}
```

## Helpful Docs

- `treefmt-nix`: `https://github.com/numtide/treefmt-nix`
- `git-hooks.nix`: `https://github.com/cachix/git-hooks.nix`

## Known Quirks Here

- The hook can rewrite files. Re-stage task-related files after it runs.
- `repo-gate` is a good handoff check, but use judgment for doc-only or clearly isolated changes.
- Import upstream flake modules from top-level `inputs`. Use `inputs'` only inside `perSystem` for system-qualified packages.
- Use top-level `self` for source-tree paths like `treefmt.projectRoot`. Use `self'` only inside `perSystem` when referring to built outputs.
- Prefer module outputs like `config.treefmt.build.wrapper` over rebuilding tool paths by hand.