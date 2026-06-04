---
name: secrets-and-auth
description: Use when touching secrets, sops-nix, auth tokens, OpenCode provider auth, MCP auth, OAuth/API keys, Caddy local CA wiring, or service credentials in newxos.
---

# Secrets And Auth

Use this skill for high-impact secret and authentication wiring.

## Inspect First

- Read `AGENTS.md` safety rules.
- Read secret/auth routes in `docs/agent-index.md`.
- Read relevant pitfalls in `docs/pitfalls.md`.
- Inspect wiring, paths, permissions, and filenames before touching encrypted payloads.

## Rules

- Never print decrypted secret payloads.
- Prefer checking paths, ownership, permissions, and module wiring.
- Keep provider auth user-controlled unless explicitly requested otherwise.
- Route GitHub/OpenCode token wiring through sops-managed secrets where the repo already does so.
- Do not commit generated auth state, OAuth tokens, provider caches, or plaintext credentials.
- Require explicit confirmation before rotating secrets or changing recipients.
- Require explicit confirmation before deleting secret files or large auth state directories.

## Procedure

1. Identify the secret owner and consumer.
2. Verify whether wiring can be fixed without reading plaintext.
3. Check sops-nix module paths and activation permissions.
4. Preserve existing secret names and mount paths unless a rename is required.
5. Run narrow Nix evaluation/build checks for wiring changes.

## Do Not

- Use shell commands that dump secret contents.
- Add API keys to docs, memory, commits, logs, or config examples.
- Make broad auth changes while solving a narrow wiring issue.
