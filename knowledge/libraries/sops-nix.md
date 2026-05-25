---
title: sops-nix
type: note
permalink: newxos/libraries/sops-nix
---

# sops-nix

`sops-nix` is the repo's secret provisioning path.

## Observations

- [fact] Decrypts encrypted files at activation time; installs secrets onto target system or user environment
- [technique] Keep encrypted payloads under `secrets/`; keep recipient rules in `.sops.yaml`
- [fact] Age key placement and installer key handling are owned by the SOPS and installation modules
- [decision] Do not inspect secret plaintext when wiring alone is enough

## Relations

- relates_to [[Workflow]]
- relates_to [[Flake Structure]]

## What It Does Here

- Decrypts encrypted files at activation time.
- Installs secrets onto the target system or user environment.
- Provides the repo's wrapped `sops` command for editing with the configured age identity.

## Basics

- Keep encrypted payloads under `secrets/`.
- Keep recipient rules in `.sops.yaml`.
- Read SOPS and installation modules for exact key paths and secret file wiring.
- Related reading: [[Workflow]], [[Flake Structure]].

## Helpful Docs

- `sops-nix`: `https://github.com/Mic92/sops-nix`
- `sops`: `https://github.com/getsops/sops`
- `age`: `https://age-encryption.org/`
- `ssh-to-age`: `https://github.com/Mic92/ssh-to-age`

## Known Quirks

- The wrapped `sops` command uses `SOPS_AGE_KEY_CMD` so editing can happen as the normal user while the age key stays root-owned.
- Public companions like `*.pub` are fine to track normally. Private keys and tokens are not.
- Do not inspect secret plaintext when wiring alone is enough.

## Installer Media

- Installer media key embedding and first-install key transfer are owned by `modules/installation/` and install helpers.
- Do not document secret paths or payload details here beyond the ownership rule; inspect source wiring without printing secret contents.
