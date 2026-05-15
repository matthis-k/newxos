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
- The repo also exposes `repo-gate`, which stages all current worktree changes into a temporary git index and runs the managed pre-commit graph against that snapshot.
- The managed pre-commit flow is split into ordered hooks for flake generation, early statix fixes, conditional Neovim lock generation, formatting, flake checks, knowledge reindex, and hook reinstall.

## Basics

- Use `repo-gate` when you want the actual managed pre-commit behavior, but evaluated over the whole worktree instead of only the staged set.
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
      writeFlake = pkgs.writeShellScriptBin "repo-write-flake" ''
        set -euo pipefail
        ${pkgs.nix}/bin/nix run "path:$PWD#write-flake"
      '';

      flakeCheck = pkgs.writeShellScriptBin "repo-flake-check" ''
        set -euo pipefail
        ${pkgs.nix}/bin/nix flake check "path:$PWD"
      '';

      updateKnowledgeIndex = pkgs.writeShellScriptBin "repo-update-knowledge-index" ''
        set -euo pipefail
        ${pkgs.nix}/bin/nix run "path:$PWD#newxos" -- memory reindex
      '';

      reinstallGitHooks = pkgs.writeShellScriptBin "repo-install-git-hooks" ''
        set -euo pipefail
        ${pkgs.nix}/bin/nix run "path:$PWD#install-git-hooks"
      '';

      repoGate = pkgs.writeShellScriptBin "repo-gate" ''
        set -euo pipefail
        ${lib.getExe writeFlake}
        ${lib.getExe self'.packages.write-nvim-pack-lock}
        ${config.treefmt.build.wrapper}/bin/treefmt
        ${lib.getExe flakeCheck}
      '';
    in {
      pre-commit.settings.hooks.repo-write-flake = {
        enable = true;
        entry = lib.getExe writeFlake;
        pass_filenames = false;
        always_run = true;
      };

      pre-commit.settings.hooks.statix = {
        enable = true;
        after = [ "repo-write-flake" ];
        entry = "${pkgs.statix}/bin/statix fix";
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-write-nvim-pack-lock = {
        enable = true;
        entry = lib.getExe self'.packages.write-nvim-pack-lock;
        after = [ "statix" ];
        files = "^flake\\.lock$";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.repo-fmt = {
        enable = true;
        entry = "${config.treefmt.build.wrapper}/bin/treefmt";
        after = [ "statix" "repo-write-nvim-pack-lock" ];
        pass_filenames = false;
        always_run = true;
      };

      pre-commit.settings.hooks.repo-flake-check = {
        enable = true;
        entry = lib.getExe flakeCheck;
        after = [ "repo-fmt" ];
        pass_filenames = false;
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-update-knowledge-index = {
        enable = true;
        entry = lib.getExe updateKnowledgeIndex;
        after = [ "repo-fmt" ];
        files = "^knowledge/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.repo-install-git-hooks = {
        enable = true;
        entry = lib.getExe reinstallGitHooks;
        after = [ "repo-flake-check" "repo-update-knowledge-index" ];
        files = "^modules/workflow\\.nix$";
        pass_filenames = false;
      };

      packages.fmt = config.treefmt.build.wrapper;
      packages.install-git-hooks = pkgs.writeShellScriptBin "install-git-hooks" ''
        set -euo pipefail
        ${config.pre-commit.installationScript}
      '';
      packages.repo-gate = repoGate;
    };
}
```

## Helpful Docs

- `treefmt-nix`: `https://github.com/numtide/treefmt-nix`
- `git-hooks.nix`: `https://github.com/cachix/git-hooks.nix`

## Known Quirks Here

- The hook can rewrite files. Re-stage task-related files after it runs.
- The hook order is controlled with `after`/`before`; do not rely on attrset order.
- `statix` runs near the front of the hook graph so Nix rewrites land before `treefmt` and `flake check`.
- The managed `repo-write-nvim-pack-lock` hook only runs when staged `flake.lock` matches.
- The managed `repo-flake-check` hook only runs when staged `*.nix` files match.
- The managed `repo-update-knowledge-index` hook only runs when staged `knowledge/` files match.
- The managed `repo-install-git-hooks` hook only runs when staged `modules/workflow.nix` matches.
- `repo-gate` is a good handoff check because it reuses the real hook graph without requiring you to stage files first.
- Import upstream flake modules from top-level `inputs`. Use `inputs'` only inside `perSystem` for system-qualified packages.
- Use top-level `self` for source-tree paths like `treefmt.projectRoot`. Use `self'` only inside `perSystem` when referring to built outputs.
- Prefer module outputs like `config.treefmt.build.wrapper` over rebuilding tool paths by hand.
