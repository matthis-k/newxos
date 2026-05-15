---
id: decision-2026-05-11-local-memory-index
type: decision
title: Use a local disposable memory index
status: accepted
tags:
- memory
- basic-memory
- search
- local
links:
- agents-basic-memory
updated: 2026-05-11
permalink: newxos/decisions/2026-05-11-local-memory-index
---

# Use a local disposable memory index

## Observations

- [fact] Project needs semantic search without committing generated databases
- [decision] Use Basic Memory with local FastEmbed semantic search
- [fact] Generated DB and indexes remain machine-local; index can be rebuilt from Markdown

## Relations

- relates_to [[agents-basic-memory]]

## Context

The project needs semantic search without committing generated databases.

## Decision

Use Basic Memory with local FastEmbed semantic search.

Set:

```text
BASIC_MEMORY_CONFIG_DIR=.cache/basic-memory
BASIC_MEMORY_MCP_PROJECT=newxos
BASIC_MEMORY_SEMANTIC_EMBEDDING_PROVIDER=fastembed
```

## Consequences

- Search works locally.
- No OpenAI embedding provider is required.
- Generated DB and indexes remain machine-local.
- The index can be rebuilt from Markdown.
