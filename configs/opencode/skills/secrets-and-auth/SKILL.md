---
name: secrets-and-auth
description: Use when touching secrets, sops-nix, auth tokens, OpenCode provider auth, MCP auth, OAuth/API keys, Caddy local CA wiring, or service credentials in newxos.
---

# Secrets and Auth

## Core Rule

Prefer checking wiring, paths, permissions, and filenames over reading plaintext. Never print or commit decrypted secrets.

## Inspect First

- `AGENTS.md` — safety rules and secret policies
- `docs/pitfalls.md` — secrets and containers section
- `modules/common/sops.nix` — sops-nix module wiring
- `modules/dev/opencode.nix` — OpenCode/MCP auth wiring
- `.sops.yaml` — recipient rules

## Ownership Map

| Path | Owns |
|------|------|
| `secrets/` | Encrypted sops-nix payloads (age) |
| `.sops.yaml` | Recipient rules |
| `modules/common/sops.nix` | sops-nix activation, key placement |
| `modules/dev/opencode.nix` | OpenCode token wiring, MCP server definitions |
| `modules/installation/` | Installer key handling |

## Change Routing

| Symptom | Edit |
|---------|------|
| Secret not decrypting at activation | Check recipient rules in `.sops.yaml`, key placement |
| Token auth failing | Verify module wiring paths, not secret content |
| New secret needed | Add encrypted file to `secrets/`, update `.sops.yaml` recipients |
| Provider auth broken | Check generated settings in `opencode.nix` |
| MCP server auth failing | Inspect server wiring in `opencode.nix` |
| Caddy CA not trusted by apps | Publish to world-readable path (`/run/caddy-local-root.crt`) |

## Procedure

1. Identify secret owner and consumer.
2. Check wiring, paths, and permissions without reading plaintext.
3. Verify sops-nix module paths and activation permissions.
4. Preserve existing secret names and mount paths unless rename is required.
5. Run narrow Nix evaluation/build checks for wiring changes.

## Validation

- `nix flake show "path:$PWD"` — verify packages/outputs
- `nix flake check "path:$PWD"` — full evaluation
- `nix run "path:$PWD#repo-gate"` for handoff

## Do Not

- Print decrypted secret payloads.
- Use shell commands that dump secret contents.
- Add API keys to docs, memory, commits, logs, or config examples.
- Commit OAuth tokens, provider caches, or plaintext credentials.
- Make broad auth changes while solving narrow wiring issues.
- Rotate secrets or change recipients without explicit confirmation.
- Delete secret files or large auth state directories without explicit confirmation.

## Done Criteria

- Wiring verified without reading plaintext.
- No plaintext secrets in output, diffs, or commits.
- Nix evaluation passes.
