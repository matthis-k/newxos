---
id: decision-2026-05-11-use-basic-memory
type: decision
title: Use Basic Memory for agent knowledge
status: accepted
tags:
- memory
- basic-memory
- agents
- decision
links:
- agents-basic-memory
- decision-2026-05-11-local-memory-index
- decision-2026-05-11-markdown-only-git-history
updated: 2026-05-11
permalink: newxos/decisions/2026-05-11-use-basic-memory
---

# Use Basic Memory for agent knowledge

## Observations

- [fact] Repo's `knowledge/` directory was growing and becoming harder to navigate through static file lists in `opencode.json`
- [decision] Adopt Basic Memory as primary semantic search layer over `knowledge/`
- [technique] Point Basic Memory at whole `knowledge/` directory; keep `opencode.json` instructions minimal
- [fact] Agents can search knowledge semantically instead of relying on prompt-loaded files

## Relations

- relates_to [[agents-basic-memory]]
- relates_to [[decision-2026-05-11-local-memory-index]]
- relates_to [[decision-2026-05-11-markdown-only-git-history]]

## Context

The repo's `knowledge/` directory was growing and becoming harder to navigate through static file lists in `opencode.json`.

## Decision

Adopt Basic Memory as the primary semantic search layer over `knowledge/`.

- Point Basic Memory at the whole `knowledge/` directory.
- Keep `opencode.json` instructions minimal (stable entrypoints only).
- Use Basic Memory MCP for hybrid text/vector search during agent sessions.

## Consequences

- Agents can search knowledge semantically instead of relying on prompt-loaded files.
- `opencode.json` stays small and stable.
- Local index is disposable and rebuildable.
