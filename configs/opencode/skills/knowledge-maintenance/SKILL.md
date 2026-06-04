---
name: knowledge-maintenance
description: Use when editing docs, ADRs, pitfalls, contracts, playbooks, test cases, or Basic Memory content in newxos.
---

# Knowledge Maintenance

Use this skill for maintaining `docs/` and repo-owned agent knowledge.

## Inspect First

- Read `docs/playbooks/maintain-docs.md`.
- For memory storage rules, read `docs/playbooks/basic-memory.md`.
- For accepted knowledge policy, read `docs/adr/0004-knowledge-as-index.md`.
- Check nearby docs before creating new files.

## Rules

- Docs are an index to owners, invariants, decisions, procedures, and pitfalls.
- Source files are truth for exact option values, package lists, generated settings, and behavior.
- Do not copy upstream documentation into this repo.
- Do not duplicate content across docs.
- Use ADRs for durable decisions future agents might reverse.
- Use pitfalls for recurring mistakes with a concrete fix.
- Use contracts for interface and boundary rules.
- Use playbooks for repeatable procedures.
- Use test-cases for detailed behavioral expectations.

## Procedure

1. Classify the information before editing.
2. Prefer updating an existing doc over adding a new one.
3. Keep content compact, durable, and project-specific.
4. Link to source owners instead of mirroring exact values.
5. Remove stale or generic content when found.
6. Reindex Basic Memory after committed Markdown changes.

## Checks

- Format docs with `nix run "path:$PWD#fmt"` when practical.
- Reindex memory with `nix run "path:$PWD#newxos" -- memory reindex` after `docs/**` changes.

## Do Not

- Store secrets in memory or docs.
- Commit generated Basic Memory state under `.cache/basic-memory/`.
- Add empty placeholder docs.
