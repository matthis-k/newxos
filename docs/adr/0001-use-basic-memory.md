# ADR-0001: Use Basic Memory for agent knowledge

## Status

Accepted

## Context

The repo's agent knowledge base was growing and becoming harder to navigate through static file lists in `opencode.json`. Relying on prompt-loaded files to give agents context was fragile and did not scale.

## Decision

Adopt Basic Memory as the primary semantic search layer over `docs/`. Point Basic Memory at the whole `docs/` directory. Keep `opencode.json` instructions minimal (stable entrypoints only). Use Basic Memory MCP for hybrid text/vector search during agent sessions.

## Consequences

- Agents can search knowledge semantically instead of relying on prompt-loaded files.
- `opencode.json` stays small and stable.
- Local index is disposable and rebuildable from Markdown.
