---
title: host-and-user-layout
type: note
permalink: newxos/patterns/host-and-user-layout
---

# Host And User Layout

Concrete systems and real users live near their own files.

## What It Means Here

- Concrete NixOS systems live under `modules/hosts/<hostname>/`.
- Real users live under `modules/users/<name>/`.
- Shared system behavior stays in shared top-level modules.
- Hosts import shared aspects and keep host-local details nearby.

## Practical Rules

- Keep boot, hardware, storage, swap, and installer-only details near the host.
- Keep user-specific Home Manager config near the user.
- A user directory can define both Home Manager and NixOS-side user wiring when that is clearest.
- Installer media hosts should follow the same pattern instead of becoming special global snowflakes.
- Related reading: [Flake Structure](../flake-structure.md#moduleshosts), [home-manager](../libraries/home-manager.md), [disko](../libraries/disko.md).

## Known Quirks

- Generated hardware config should stay focused on detected hardware defaults, not duplicate storage truth already handled by `disko`.
- Host-local complexity is a reason to add nearby files, not a reason to centralize everything.