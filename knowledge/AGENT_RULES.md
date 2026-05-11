---
id: agent-rules
type: workflow
title: Agent rules
status: active
tags:
- agents
- workflow
- memory
links:
- agents-basic-memory
- architecture-index
updated: 2026-05-11
permalink: newxos/agent-rules
---

# Agent rules

This repository uses Markdown project memory under `knowledge/`.

## Before work

Search project memory before making non-trivial changes.

Use, in order:

1. Basic Memory search
2. `rg` over `knowledge/`
3. source inspection

## During work
## During work

### Task hygiene

Check `knowledge/tasks/` and related task notes before committing. If a commit resolves, partially completes, or changes the scope of a tracked task, update or remove the task note in the same commit.

Create or update memory when learning durable project information:

- architecture rules
- project conventions
- accepted decisions
- recurring issues
- durable TODOs
- upstream source notes
- debugging lessons

Do not store:

- secrets
- private keys
- decrypted SOPS values
- tokens
- raw logs
- transient scratchpad reasoning
- large generated output

## After work

Update memory if the change affects:

- architecture
- Nix module conventions
- OpenCode/MCP setup
- install/recovery procedures
- theming behavior
- known issues
- durable tasks

Prefer updating an existing note over creating a duplicate.

Use stable IDs for links.