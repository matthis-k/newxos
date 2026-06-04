# ADR-0002: Keep memory Git history Markdown-only

## Status

Accepted

## Context

Basic Memory needs generated local state for search and semantic retrieval (SQLite, index files, embeddings). Committing generated state would bloat the repository and make reviews harder.

## Decision

Commit only Markdown memory files under `docs/`. Store generated Basic Memory state under `.cache/basic-memory/` which is gitignored.

## Consequences

- Git history remains reviewable (only Markdown diffs).
- Local index state can be deleted and rebuilt.
- Users should run `newxos memory reindex` after clone, branch switch, or large memory edits.
