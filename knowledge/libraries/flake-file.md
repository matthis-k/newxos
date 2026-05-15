---
title: flake-file
type: note
permalink: newxos/libraries/flake-file
---

# flake-file

`flake-file` generates the root `flake.nix` from declarations in repo modules.

## Observations

- [fact] Keeps the root `flake.nix` thin and generated
- [decision] Treat `modules/` as the source of truth; do not hand-edit generated `flake.nix`
- [technique] After changing `flake-file` declarations, run `nix run "path:$PWD#write-flake"`
- [fact] Works with the dendritic layout so wiring stays close to the feature that needs it

## Relations

- relates_to [[Workflow]]
- relates_to [[Dendritic Feature Modules]]

## What It Does Here

- Keeps the root `flake.nix` thin and generated.
- Lets feature modules declare inputs and structure instead of editing the root by hand.
- Works with the dendritic layout so wiring stays close to the feature that needs it.

## Basics

- Treat `modules/` as the source of truth.
- After changing `flake-file` declarations, run `nix run "path:$PWD#write-flake"`.
- Do not hand-edit generated `flake.nix`.
- Related reading: [[Workflow]], [[Dendritic Feature Modules]].

## Short Example

```nix
flake-file.inputs.home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

## Helpful Docs

- Overview: `https://flake-file.oeiuwq.com/overview/`

## Known Quirks

- If `flake.nix` looks wrong, the usual fix is to update the module source and rerun `write-flake`.
- `nix flake show/check` can mislead you if the generated file is stale.
- Output discovery and CI can diverge from local edits if you forget regeneration.
