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

Content not yet written. See [sops-nix](../libraries/sops-nix.md) for current secret wiring guidance.

## Rules

- Never store plaintext secrets in git.
- Never print secret values in commits, logs, or agent output.
- Check secret wiring through module declarations, not by reading decrypted values.
