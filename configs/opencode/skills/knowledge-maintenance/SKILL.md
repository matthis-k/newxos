---
name: knowledge-maintenance
description: Use when editing docs, ADRs, pitfalls, contracts, playbooks, test cases, or Basic Memory content in newxos.
---

# Knowledge Maintenance

## Core Rule

Docs index to owners, decisions, and procedures. Source files are truth for exact option values, package lists, and generated settings. Never duplicate upstream docs or store secrets.

## Inspect First

- `docs/playbooks/maintain-docs.md` — classification, filtering, relevance standard
- `docs/playbooks/basic-memory.md` — storage model, commands, rules
- `docs/adr/0004-knowledge-as-index.md` — knowledge policy
- Nearest existing doc for pattern matching

## Document Types and Routing

| Need | Create/Update |
|------|--------------|
| Future agents might reverse this decision | ADR in `docs/adr/<NNNN>-<kebab>.md` |
| Interface or boundary rules | Contract in `docs/contracts/` |
| Step-by-step procedure | Playbook in `docs/playbooks/` |
| Repeatable agent mistake with fix | Entry in `docs/pitfalls.md` |
| Architecture layout or invariant | Section in `docs/architecture.md` |
| Detailed behavioral expectations | Test case in `docs/test-cases/` |

## Procedure

1. Classify the information before editing.
2. Prefer updating an existing doc over creating a new one.
3. Keep content compact, durable, and project-specific.
4. Link to source owners instead of mirroring exact values.
5. Remove stale or generic content when found.
6. Reindex Basic Memory after committed markdown changes.

## Validation

- Format docs: `nix run "path:$PWD#fmt"`
- Reindex memory: `nix run "path:$PWD#newxos" -- memory reindex`

## Do Not

- Store secrets in memory or docs.
- Commit generated Basic Memory state under `.cache/basic-memory/`.
- Copy upstream documentation into this repo.
- Duplicate content across docs.
- Add empty placeholder docs.
- Duplicate exact package lists or option values in docs.

## Done Criteria

- Information classified correctly (ADR vs playbook vs pitfall vs contract).
- No duplicated content across docs.
- Existing docs preferred over new files.
- Basic Memory reindexed if `docs/**` changed.
