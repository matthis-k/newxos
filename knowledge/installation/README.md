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
- [technique] `newxos first-install <host>` partitions, formats, installs the selected host, and copies the flake to `/home/<user>/newxos`
- [fact] The live USB creates and autologins as user `newxos`, exports `NEWXOS_FLAKE=/home/newxos/newxos`, and seeds that mutable flake from `/etc/newxos-source` before the post-install `$HOME/newxos` copy exists
- [fact] Related to [[issue-nixos-install-oom]] for low-memory installation considerations

## Relations

- part_of [[Knowledge]]
- relates_to [[issue-nixos-install-oom]]
- relates_to [[disko]]
- relates_to [[nh-nom]]

## USB flow

1. Boot the `newxos-live-usb` installer media.
2. Run `newxos first-install <host>`.
3. The command installs the full `<host>` directly and copies the bundled flake to `/home/<derived-user>/newxos`.
4. The derived user defaults to the part of the host name before the first dash, e.g. `matthisk-desktop-newxos` copies to `/home/matthisk/newxos`.

## Installer SOPS Key

Run `newxos build-iso --key /var/lib/sops-nix/key.txt` when you want the live USB to carry the age key. The command uses an impure ISO build and escalates with `sudo` when the key path is not readable by the current user.

When the key is embedded:

- the live media copies it to `/var/lib/sops-nix/key.txt` at activation
- the live media decrypts `/run/secrets/github_token` for OpenCode GitHub MCP use
- the wrapped `opencode` package exports GitHub token environment variables from `/run/secrets/github_token` when present
- `newxos first-install <host>` copies the key to `/mnt/var/lib/sops-nix/key.txt` before `nixos-install`, leaving it on the installed host

Without `NEWXOS_INSTALLER_SOPS_KEY`, installer media still evaluates purely but has no embedded SOPS key or decrypted GitHub token.

## Related

- [[issue-nixos-install-oom]]
