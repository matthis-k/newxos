---
id: architecture-import-tree
type: concept
title: import-tree
status: active
tags:
- architecture
- import-tree
- nix
links:
- architecture-index
- newxos/flake-structure
updated: 2026-05-11
permalink: newxos/architecture/import-tree
---

# import-tree

`import-tree` recursively imports the `modules/` tree so that every `.nix` file under `modules/` becomes a NixOS or flake module.

## Observations

- [fact] New `.nix` files under `modules/` are automatically picked up
- [fact] Import order follows the filesystem tree
- [technique] If a new module is not being seen, check that it is a valid `.nix` file under `modules/`

## Relations

- part_of [[architecture-index]]
- relates_to [[Flake Structure]]

## Key points

- New `.nix` files under `modules/` are automatically picked up.
- The import order follows the filesystem tree.
- If a new module is not being seen, check that it is a valid `.nix` file under `modules/`.

## Upstream docs

<https://import-tree.oeiuwq.com>
