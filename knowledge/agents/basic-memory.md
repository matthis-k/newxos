---
id: agents-basic-memory
type: concept
title: Basic Memory integration
status: active
tags:
- agents
- memory
- basic-memory
- mcp
links:
- agents-opencode
- decision-2026-05-11-markdown-only-git-history
- decision-2026-05-11-local-memory-index
- task-basic-memory-package-with-uv2nix
updated: 2026-05-25
permalink: newxos/agents/basic-memory
---

# Basic Memory integration

Basic Memory provides searchable local project memory for agents.

## Observations

- [fact] Canonical memory is committed as Markdown under `knowledge/**/*.md`
- [fact] Generated state is local and ignored under `.cache/basic-memory/`
- [technique] Basic Memory packaging is owned by the OpenCode/dev tooling modules and the `uv/basic-memory/` workspace
- [fact] Semantic embeddings use FastEmbed (local, no cloud API)
- [requirement] Commit Markdown only; do not commit SQLite, index, cache, or embedding files

## Relations

- relates_to [[agents-opencode]]
- relates_to [[decision-2026-05-11-markdown-only-git-history]]
- relates_to [[decision-2026-05-11-local-memory-index]]

## Upstream

- Docs: <https://docs.basicmemory.com>
- Default embedding provider: FastEmbed (local)

## Storage Model

Canonical memory is committed as Markdown under `knowledge/`. Generated database, index, cache, and embedding state is local and ignored.

## Commands

```bash
newxos memory reindex
newxos memory reset
```

## Packaging Ownership

- Python workspace: `uv/basic-memory/`.
- Nix packaging and wrapper integration: dev/OpenCode tooling modules.
- Exact `uv2nix`, virtualenv, and runtime input details belong in source.

## Rules

- Commit Markdown only.
- Do not commit SQLite, index, cache, or embedding files.
- Do not store secrets.
- Prefer linking existing notes over duplicating content.
- Promote stable, important lessons into topic index pages.
- When updating `uv/basic-memory/uv.lock`, run `nix flake lock` to update flake.lock.

## Embedding Model

Semantic embeddings use a local provider so project search does not require a cloud API. Read the OpenCode/dev tooling source for exact provider config and environment wiring.
