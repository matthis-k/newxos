---
title: host-and-user-layout
type: note
permalink: newxos/patterns/host-and-user-layout
---

# Host And User Layout

Concrete systems and real users live near their own files.

## Observations

- [fact] Concrete NixOS systems under `modules/hosts/<hostname>/`; real users under `modules/users/<name>/`
- [decision] Shared system behavior stays in shared modules such as `modules/common/`
- [technique] A user directory can define both Home Manager and NixOS-side user wiring when that is clearest
- [decision] Host-specific user deltas belong in host-local user modules that import the shared user module
- [fact] Generated hardware config should stay focused on detected hardware defaults, not duplicate storage truth handled by `disko`

## Relations

- relates_to [[Flake Structure]]
- relates_to [[home-manager]]
- relates_to [[disko]]

## What It Means Here

- Concrete NixOS systems live under `modules/hosts/<hostname>/`.
- Real users live under `modules/users/<name>/`.
- Shared system behavior stays in shared modules such as `modules/common/`.
- Hosts import shared aspects and keep host-local details nearby.
- If a user is mostly the same across hosts, import the shared user module from each host instead of duplicating `users.users` or Home Manager wiring.
- If a host needs user-specific differences, add a host-local `modules/hosts/<hostname>/users/<name>.nix` module that imports the shared user module and adds only the delta.

## Practical Rules

- Keep boot, hardware, storage, swap, and installer-only details near the host.
- Keep reusable multi-host system bundles under `modules/common/`.
- Keep user-specific Home Manager config near the user.
- A user directory can define both Home Manager and NixOS-side user wiring when that is clearest.
- Installer media hosts should follow the same pattern instead of becoming special global snowflakes.
- Related reading: [[Flake Structure]], [[home-manager]], [[disko]].

## Known Quirks

- Generated hardware config should stay focused on detected hardware defaults, not duplicate storage truth already handled by `disko`.
- Host-local complexity is a reason to add nearby files, not a reason to centralize everything.
