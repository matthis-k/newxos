---
title: nh-nom
type: note
permalink: newxos/libraries/nh-nom
---

# nh And nom

This repo uses `nh` and `nix-output-monitor` through repo-owned `newxos` wrapper package.

## Observations

- [fact] The repo-owned `newxos` wrapper is the command entrypoint for rebuild, install, ISO, clean, and flake helper flows
- [technique] Wrapper source owns exact subcommands, defaults, environment variables, and host inference behavior
- [decision] Use `path:$PWD` or the wrapper's path-based flake handling during agent work so local unadded changes are visible when intended
- [fact] `nom` is used for richer build output where it fits; plain `nix` remains better for some structured output

## Relations

- relates_to [[home-manager]]
- relates_to [[Workflow]]

## What It Does Here

- Wraps common `nh`, `nix`, installer, ISO, cleanup, and flake operations behind a repo-owned command.
- Keeps command ergonomics and host/path inference in source instead of scattered shell aliases.
- Gives installer media and normal hosts one common command surface.

## Basics

- Read the wrapper package source for exact subcommands, environment variables, completions, and default retention settings.
- Related installation behavior lives in `modules/installation/`.
- Related reading: [[home-manager]], [[Workflow]].

## Helpful Docs

- `nh`: `https://github.com/nix-community/nh`
- `nix-output-monitor`: `https://github.com/maralorn/nix-output-monitor`

## Known Quirks

- `newxos flake show` stays plain `nix flake show`; there is no useful `nom` wrapper for that output.
- Host inference depends on wrapper-managed environment; read source for current fallback behavior.
- `newxos flake run` targets runnable flake attrs like package or app names, not NixOS host names.
