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

## Rules

- Never hand-edit `flake.nix`.
- Edit `modules/` declarations and run `nix run "path:$PWD#write-flake"` to regenerate.
- The generator reads flake-file module declarations from the module tree.
- Verify changes with `nix flake show "path:$PWD"` and `nix flake check "path:$PWD"`.

## Related

- [[architecture-import-tree]]

## Upstream docs

<https://flake-file.oeiuwq.com/overview/>
