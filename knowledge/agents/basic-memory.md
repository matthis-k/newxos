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
updated: 2026-05-11
permalink: newxos/agents/basic-memory
---

# Basic Memory integration

Basic Memory provides searchable local project memory for agents.

## Upstream

- Docs: <https://docs.basicmemory.com>
- Default embedding provider: FastEmbed (local)

## Storage model

Canonical memory is committed as Markdown:

```text
knowledge/**/*.md
```

Generated state is local and ignored:

```text
.cache/basic-memory/
```

## Commands

```bash
newxos memory reindex
newxos memory reset
```

## Packaging

Basic Memory is built with `uv2nix` instead of running via `uvx` at runtime.

The uv workspace lives in `uv/basic-memory/` with `pyproject.toml` and `uv.lock`.

In `modules/opencode.nix`, the package is built through:
1. `uv2nix.lib.workspace.loadWorkspace` — loads the uv workspace
2. `mkPyprojectOverlay` — creates a Nix overlay from the workspace
3. `pyproject-nix.build.packages` — builds the Python package set
4. `mkVirtualEnv` — creates a virtualenv with basic-memory and all dependencies

The virtualenv is used as `runtimeInputs` in the shell applications.

## Rules

- Commit Markdown only.
- Do not commit SQLite, index, cache, or embedding files.
- Do not store secrets.
- Prefer linking existing notes over duplicating content.
- Promote stable, important lessons into topic index pages.
- When updating `uv/basic-memory/uv.lock`, run `nix flake lock` to update flake.lock.

## Embedding model

Semantic embeddings use **FastEmbed** (local, no cloud API). Configured via:

- `semantic_embedding_provider: "fastembed"` in the Basic Memory config
- `BASIC_MEMORY_SEMANTIC_EMBEDDING_PROVIDER="fastembed"` environment variable

FastEmbed downloads its model on first run and caches it locally. No additional Nix packaging is needed — it runs within the `uv2nix`-built virtualenv.
