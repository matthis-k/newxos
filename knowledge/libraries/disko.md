---
title: disko
type: note
permalink: newxos/libraries/disko
---

# disko

`disko` is the storage layout tool for concrete NixOS hosts.

## Observations

- [fact] Defines declarative disk layouts for hosts
- [decision] Keep host-local storage wiring under `modules/hosts/<hostname>/`
- [requirement] If `disko` owns storage layout, let it stay source of truth; do not duplicate `fileSystems` or `swapDevices`
- [fact] Storage helpers are inherently destructive; validate by evaluation and build, not by casually running install flows

## Relations

- relates_to [[Host And User Layout]]
- relates_to [[Flake Structure]]

## What It Does Here

- Defines declarative disk layouts for hosts.
- Keeps storage decisions near the host that owns them.
- Helps installer and first-boot flows stay reproducible.

## Basics

- Keep host-local storage wiring under `modules/hosts/<hostname>/`.
- If `disko` owns the storage layout, let it stay the source of truth.
- Generated hardware files should not duplicate `fileSystems`, `swapDevices`, or similar storage declarations when `disko` already manages them.
- Related reading: [[Host And User Layout]], [[Flake Structure]].

## Helpful Docs

- Docs index: `https://github.com/nix-community/disko/blob/master/docs/INDEX.md`
- Quickstart: `https://github.com/nix-community/disko/blob/master/docs/quickstart.md`
- Reference: `https://github.com/nix-community/disko/blob/master/docs/reference.md`

## Known Quirks

- Storage helpers are inherently destructive. Validate by evaluation and build where possible, not by casually running install flows.
- When a host layout is confusing, trust upstream disko docs over copying patterns blindly from another host.
