---
id: secrets-index
type: index
title: Secrets
status: active
tags:
- secrets
- sops-nix
- agenix
updated: 2026-05-11
permalink: newxos/secrets/readme
---

# Secrets

This folder covers secret management, encryption, and provisioning.

## Observations

- [fact] Content not yet written
- [requirement] Never store plaintext secrets in git; never print secret values in commits, logs, or agent output
- [technique] Check secret wiring through module declarations, not by reading decrypted values

## Relations

- part_of [[Knowledge]]
- relates_to [[sops-nix]]

Content not yet written. See [[sops-nix]] for current secret wiring guidance.

## Rules

- Never store plaintext secrets in git.
- Never print secret values in commits, logs, or agent output.
- Check secret wiring through module declarations, not by reading decrypted values.
