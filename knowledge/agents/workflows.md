---
id: agents-workflows
type: workflow
title: Agent workflows
status: active
tags:
- agents
- workflow
links:
- agents-index
- agent-rules
updated: 2026-05-11
permalink: newxos/agents/workflows
---

# Agent workflows

## Observations

- [technique] Search in order: Basic Memory search first, `rg` as exact-search fallback, inspect source files last
- [fact] For exact terms, paths, Nix options, errors, and identifiers, use `rg`
- [fact] For conceptual queries, use Basic Memory hybrid search
- [fact] Managed pre-commit hook runs `newxos memory reindex` automatically when staged files under `knowledge/` change

## Relations

- relates_to [[agents-index]]
- relates_to [[agent-rules]]

Before non-trivial work:

```bash
newxos memory reindex || true
```

Then search:

1. Basic Memory search first
2. `rg` as exact-search fallback
3. Inspect source files last

For exact terms, paths, Nix options, errors, and identifiers, use `rg`.

For conceptual queries, use Basic Memory hybrid search.

After work:

```bash
newxos memory reindex
```

The managed pre-commit hook also runs `newxos memory reindex` automatically when staged files under `knowledge/` change.

Then ensure no generated state is staged:

```bash
git status --short
```

Generated files under `.cache/` must not appear.
