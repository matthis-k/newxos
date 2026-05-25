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
1. Verbose initrd output can override Plymouth's graphics mode
2. Non-quiet kernel output can interrupt Plymouth display

When NVIDIA driver takes over the framebuffer from `simpledrm`, the verbose initrd output pushes Plymouth out of the display pipeline entirely.

## Fix Location

Host-local boot and kernel parameter changes belong under the affected host in `modules/hosts/`.

## Rule
For Plymouth + NVIDIA + LUKS setups, keep initrd output quiet enough for Plymouth to own the display path. Put exact NixOS option values beside the host boot config.

## Related
- [[plymouth-nvidia-luks-integration]]
- [[Host And User Layout]]
