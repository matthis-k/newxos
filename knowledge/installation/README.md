---
id: installation-index
type: index
title: Installation
status: active
tags:
- installation
- nixos
updated: 2026-05-11
permalink: newxos/installation/readme
---

# Installation

This folder covers NixOS installation procedures and recovery.

## Observations

- [fact] New installs use `newxos first-install <host>` from the live USB
- [fact] Hosts tagged in `newxos.installer.stagingHosts.<host>` automatically install via generated `<host>-staging` first
- [technique] Tagged hosts use a base module named `<host>-base` by default for boot, storage, swap, and minimal user wiring
- [technique] `newxos first-install <host>` partitions, formats, installs either `<host>` or `<host>-staging`, and copies the flake to `/home/<user>/newxos`
- [requirement] Staging installs must include disk layout, boot, swap, networking, Nix, user access, environment variables, and the full `newxos` wrapper, but avoid desktop and Home Manager payloads
- [fact] Related to [[issue-nixos-install-oom]] for low-memory installation considerations

## Relations

- part_of [[Knowledge]]
- relates_to [[issue-nixos-install-oom]]
- relates_to [[disko]]
- relates_to [[nh-nom]]

## Low-memory USB flow

1. Mark low-memory hosts in `modules/hosts/<host>/configuration.nix` with `newxos.installer.stagingHosts.<host>.user = "<user>"`.
2. Keep host-local essentials in `flake.modules.nixos.<host>-base`; by default the generated staging host imports this base module.
3. Boot the `newxos-live-usb` installer media.
4. Run `newxos first-install matthisk-laptop-newxos`.
5. The command detects the staging tag, runs disko against `matthisk-laptop-newxos-staging`, and installs the generated staging system.
6. The installer copies the bundled flake to `/home/matthisk/newxos`.
7. Reboot without the USB.
8. Log in as `matthisk` and run `newxos os switch`.
9. The staging system exports `NEWXOS_HOST=matthisk-laptop-newxos`, so `newxos os switch` rebuilds the full host.

## Non-staging USB flow

1. Boot the `newxos-live-usb` installer media.
2. Run `newxos first-install <host>`.
3. If `<host>` is not tagged in `newxos.installer.stagingHosts`, the command installs the full `<host>` directly and copies the bundled flake to `/home/<derived-user>/newxos`.
4. The derived user defaults to the part of the host name before the first dash, e.g. `matthisk-desktop-newxos` copies to `/home/matthisk/newxos`.

## Staging contents

Generated staging hosts import shared `disko`, `locales`, `networking`, `newxos`, and `nix` modules plus `flake.modules.nixos.<host>-base` by default.

The `<host>-base` module should stay small:

- bootloader and initrd settings
- disko storage layout and swap
- minimal normal user account
- other hardware essentials required to boot

The generated staging layer adds:

- locale and networking basics
- Nix settings
- `NEWXOS_FLAKE=/home/<user>/newxos`
- the full `newxos` wrapper

It does not set passwords or add desktop, Home Manager payloads, theming, VPNs, or other large runtime features.

## Installer SOPS Key

Run `newxos build-iso --key /var/lib/sops-nix/key.txt` when you want the live USB to carry the age key. The command uses an impure ISO build and escalates with `sudo` when the key path is not readable by the current user.

When the key is embedded:

- the live media copies it to `/var/lib/sops-nix/key.txt` at activation
- the live media decrypts `/run/secrets/github_token` for OpenCode GitHub MCP use
- `newxos ai` exports GitHub token environment variables from `/run/secrets/github_token` when present
- `newxos first-install <host>` copies the key to `/mnt/var/lib/sops-nix/key.txt` before `nixos-install`, leaving it on the installed host

Without `NEWXOS_INSTALLER_SOPS_KEY`, installer media still evaluates purely but has no embedded SOPS key or decrypted GitHub token.

## Related

- [[issue-nixos-install-oom]]
