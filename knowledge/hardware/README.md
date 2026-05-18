---
id: hardware-index
type: index
title: Hardware
status: active
tags:
- hardware
updated: 2026-05-11
permalink: newxos/hardware/readme
---

# Hardware

This folder documents hardware-specific configuration and known compatibility notes.

## Observations

- [fact] `matthisk-desktop-newxos` is a desktop NixOS host for AMD CPU and NVIDIA RTX 5060 hardware
- [technique] NVIDIA desktop support uses early initrd NVIDIA modules plus `nvidia_drm.fbdev=1` and `nvidia_drm.modeset=1` for Plymouth/Wayland startup
- [fact] The desktop host uses a concrete Kingston NVMe `/dev/disk/by-id/...` disko target
- [decision] Placeholder index remains for future hardware-specific notes

## Relations

- part_of [[Knowledge]]
- relates_to [[Host And User Layout]]
- relates_to [[hyprland]]

## Desktop Host

The current desktop hardware profile includes AMD microcode, NVIDIA open kernel modules, 32-bit graphics support for Vulkan/Proton/Wine use cases, and NVIDIA power management.
