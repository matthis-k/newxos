---
title: workflow-tooling
type: note
permalink: newxos/libraries/workflow-tooling
---

# Workflow Tooling

This repo uses `treefmt-nix` and `git-hooks.nix` for formatting and pre-commit workflow.

## Observations

- [fact] `treefmt-nix` exposes formatter behind `nix run "path:$PWD#fmt"`
- [fact] `git-hooks.nix` installs and runs managed pre-commit hook
- [technique] Use `repo-gate` for actual managed pre-commit behavior evaluated over whole worktree, not just staged set
- [fact] Managed workflow wiring lives in `modules/dev/workflow.nix`; read it for exact hook definitions

## Relations

- relates_to [[Workflow]]

## What It Does Here

- `treefmt-nix` exposes the formatter behind `nix run "path:$PWD#fmt"`.
- `git-hooks.nix` installs and runs the managed pre-commit hook.
- The repo also exposes `repo-gate`, which stages all current worktree changes into a temporary git index and runs the managed pre-commit graph against that snapshot.
- Exact hook order and trigger patterns are source details in `modules/dev/workflow.nix`.

## Basics

- Use `repo-gate` when you want the actual managed pre-commit behavior, but evaluated over the whole worktree instead of only the staged set.
- `packages.fmt` comes from the treefmt wrapper.
- The default dev shell comes from the pre-commit integration.
- Related reading: [[Workflow]].

## Placement Rules

- Keep workflow behavior in `modules/dev/workflow.nix`.
- Keep extra flake inputs close to the module that consumes them.
- Keep exact pre-commit hook definitions in source, not in this note.
- If hook behavior changes conceptually, update this note and [[Workflow]].

## Helpful Docs

- `treefmt-nix`: `https://github.com/numtide/treefmt-nix`
- `git-hooks.nix`: `https://github.com/cachix/git-hooks.nix`

## Known Quirks

- The hook can rewrite files. Re-stage task-related files after it runs.
- The hook order is controlled with `after`/`before`; do not rely on attrset order.
- `statix` runs near the front of the hook graph so Nix rewrites land before `treefmt` and `flake check`.
- Read `modules/dev/workflow.nix` for current hook trigger patterns.
- `repo-gate` is a good handoff check because it reuses the real hook graph without requiring you to stage files first.
- Import upstream flake modules from top-level `inputs`. Use `inputs'` only inside `perSystem` for system-qualified packages.
- Use top-level `self` for source-tree paths like `treefmt.projectRoot`. Use `self'` only inside `perSystem` when referring to built outputs.
- Prefer module outputs like `config.treefmt.build.wrapper` over rebuilding tool paths by hand.
