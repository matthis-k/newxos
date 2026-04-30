# Workflow Tooling

This repo uses `treefmt-nix` and `git-hooks.nix` for formatting and pre-commit workflow.

## What It Does Here

- `treefmt-nix` exposes the formatter wrapper used by `nix run "path:$PWD#fmt"`.
- `git-hooks.nix` installs and runs the managed pre-commit hook.
- The repo also exposes `repo-gate`, which runs `write-flake -> fmt -> flake check`.

## Basics

- Use `repo-gate` when you want the same broad flow as pre-commit.
- `packages.fmt` comes from the treefmt wrapper.
- The default dev shell comes from the pre-commit integration.
- Related reading: [Workflow](../workflow.md).

## Helpful Docs

- `treefmt-nix`: `https://github.com/numtide/treefmt-nix`
- `git-hooks.nix`: `https://github.com/cachix/git-hooks.nix`

## Known Quirks Here

- The hook can rewrite files. Re-stage task-related files after it runs.
- `repo-gate` is a good handoff check, but use judgment when the task only touched docs or other clearly isolated files.
