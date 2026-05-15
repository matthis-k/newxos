---
id: architecture-flake-file
type: concept
title: flake-file
status: active
tags:
- architecture
- flake-file
- nix
links:
- architecture-index
- architecture-import-tree
updated: 2026-05-11
permalink: newxos/architecture/flake-file
---

# flake-file

`flake-file` generates the root `flake.nix` from repo declarations.

## Observations

- [fact] `flake.nix` is generated; never hand-edit it
- [technique] Edit `modules/` declarations and run `nix run "path:$PWD#write-flake"` to regenerate
- [requirement] Verify changes with `nix flake show "path:$PWD"` and `nix flake check "path:$PWD"`
- [fact] Generator reads flake-file module declarations from the module tree

## Relations

- part_of [[architecture-index]]
- relates_to [[architecture-import-tree]]

## Rules

- Never hand-edit `flake.nix`.
- Edit `modules/` declarations and run `nix run "path:$PWD#write-flake"` to regenerate.
- The generator reads flake-file module declarations from the module tree.
- Verify changes with `nix flake show "path:$PWD"` and `nix flake check "path:$PWD"`.

## Related

- [[architecture-import-tree]]

## Upstream docs

<https://flake-file.oeiuwq.com/overview/>
