# ADR-0003: Use a local disposable memory index

## Status

Accepted

## Context

The project needs semantic search without committing generated databases or requiring cloud embedding APIs.

## Decision

Use Basic Memory with local FastEmbed semantic search. Set:

- `BASIC_MEMORY_CONFIG_DIR=.cache/basic-memory`
- `BASIC_MEMORY_MCP_PROJECT=newxos`
- `BASIC_MEMORY_SEMANTIC_EMBEDDING_PROVIDER=fastembed`

## Consequences

- Search works locally without internet.
- No OpenAI embedding provider is required.
- Generated DB and indexes remain machine-local.
- The index can be rebuilt from Markdown.
