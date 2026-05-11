---
id: decision-2026-05-11-markdown-only-git-history
type: decision
title: Keep memory Git history Markdown-only
status: accepted
tags:
- memory
- git
- basic-memory
links:
- agents-basic-memory
updated: 2026-05-11
permalink: newxos/decisions/2026-05-11-markdown-only-git-history
---

# Keep memory Git history Markdown-only

## Context

Basic Memory needs generated local state for search and semantic retrieval.

## Decision

Commit only Markdown memory files under `knowledge/`.

Store generated Basic Memory state under:

```text
.cache/basic-memory/
```

## Consequences

- Git history remains reviewable.
- Local index state can be deleted and rebuilt.
- Users should run `newxos memory reindex` after clone, branch switch, or large memory edits.