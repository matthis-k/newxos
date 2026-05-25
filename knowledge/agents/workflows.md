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
updated: 2026-05-25
permalink: newxos/agents/workflows
---

# Agent workflows

## Observations

- [technique] Search in order: Basic Memory search first, `rg` as exact-search fallback, inspect source files last
- [fact] For exact terms, paths, Nix options, errors, and identifiers, use `rg`
- [fact] For conceptual queries, use Basic Memory hybrid search
- [fact] Managed hook behavior is defined in `modules/dev/workflow.nix`; read source for exact triggers
- [requirement] Load task-appropriate skills before specialized work, such as QML, Qt/C++, UI design, profiling, documentation, or review

## Relations

- relates_to [[agents-index]]
- relates_to [[agent-rules]]

Before non-trivial work, search:

1. Basic Memory search first
2. `rg` as exact-search fallback
3. Inspect source files last

For exact terms, paths, Nix options, errors, and identifiers, use `rg`.

For conceptual queries, use Basic Memory hybrid search.

Before specialized implementation or review, load the matching skill. For QML work, use the QML skill and Qt documentation tools as appropriate; for Qt/C++ work, use the Qt/C++ skill and Qt documentation tools.

After changing knowledge files, refresh the Basic Memory index with `newxos memory reindex` or rely on the managed hook when committing.

Before committing, ensure no generated memory state under `.cache/` is staged.
