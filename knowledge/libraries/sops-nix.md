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
- [fact] Current machine uses `/var/lib/sops-nix/key.txt` as the age key file
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
- The current machine uses `/var/lib/sops-nix/key.txt` as the age key file.
- When a program expects a fixed file path, wire the secret through `sops.secrets.<name>.path`.
- Related reading: [[Workflow]], [[Flake Structure]].

## Short Example

```nix
sops.secrets.github_token.path = "/run/secrets/github_token";
```

## Helpful Docs

- `sops-nix`: `https://github.com/Mic92/sops-nix`
- `sops`: `https://github.com/getsops/sops`
- `age`: `https://age-encryption.org/`
- `ssh-to-age`: `https://github.com/Mic92/ssh-to-age`

## Known Quirks

- The wrapped `sops` command uses `SOPS_AGE_KEY_CMD` so editing can happen as the normal user while the age key stays root-owned.
- Public companions like `*.pub` are fine to track normally. Private keys and tokens are not.
- Do not inspect secret plaintext when wiring alone is enough.
