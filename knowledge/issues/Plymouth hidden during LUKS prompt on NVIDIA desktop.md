---
title: Plymouth hidden during LUKS prompt on NVIDIA desktop
type: note
permalink: newxos/issues/plymouth-hidden-during-luks-prompt-on-nvidia-desktop
---

# Plymouth hidden during LUKS prompt on NVIDIA desktop

## Problem
Plymouth boot splash does not show during initrd LUKS password prompt on `matthisk-desktop-newxos`. Instead, raw TTY/console output is visible.

## Symptoms
- Spinning Plymouth logo not visible during boot
- LUKS password prompt shows on raw TTY instead of Plymouth graphical prompt
- Kernel messages visible during initrd phase

## Root Cause
Two issues combined:
1. `boot.initrd.verbose = true` (NixOS default) forces verbose TTY output during initrd, overriding Plymouth's graphics mode
2. Missing `"quiet"` kernel parameter allows kernel messages to interrupt Plymouth display

When NVIDIA driver takes over the framebuffer from `simpledrm`, the verbose initrd output pushes Plymouth out of the display pipeline entirely.

## Fix
Applied to `modules/hosts/matthisk-desktop-newxos/`:
- `boot.nix`: Added `boot.initrd.verbose = false;`
- `hardware-configuration.nix`: Added `"quiet"` to `boot.kernelParams`

## Rule
For Plymouth + NVIDIA + LUKS setups, always set `boot.initrd.verbose = false` and include `"quiet"` in kernel params alongside `"splash"`.

## Related
- [[plymouth-nvidia-luks-integration]]
- [[Host And User Layout]]
