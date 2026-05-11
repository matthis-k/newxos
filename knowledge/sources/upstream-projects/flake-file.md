---
id: source-flake-file
type: source
title: flake-file
status: active
tags:
- source
- flake-file
links:
- sources-index
- architecture-flake-file
updated: 2026-05-11
permalink: newxos/sources/upstream-projects/flake-file
---

# flake-file

Generates the root `flake.nix` from repo declarations.

## Upstream

- Docs: <https://flake-file.oeiuwq.com/overview/>

## Usage in this repo

- `flake.nix` is generated; never hand-edit it.
- Edit `modules/` declarations and run `nix run "path:$PWD#write-flake"`.