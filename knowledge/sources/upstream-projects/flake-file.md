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

## Observations

- [fact] Upstream docs: <https://flake-file.oeiuwq.com/overview/>
- [requirement] `flake.nix` is generated; never hand-edit it
- [technique] Edit `modules/` declarations and run `nix run "path:$PWD#write-flake"`

## Relations

- relates_to [[sources-index]]
- relates_to [[architecture-flake-file]]

## Upstream

- Docs: <https://flake-file.oeiuwq.com/overview/>

## Usage in this repo

- `flake.nix` is generated; never hand-edit it.
- Edit `modules/` declarations and run `nix run "path:$PWD#write-flake"`.
