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

## Observations

- [fact] Knowledge lives in `knowledge/` and is indexed by Basic Memory for semantic search
- [technique] Search in order: Basic Memory search → `rg` over `knowledge/` → source inspection
- [requirement] Do not store secrets, keys, decrypted SOPS values, tokens, raw logs, or transient reasoning
- [decision] Prefer updating existing notes over creating duplicates; use stable IDs for links
- [technique] Use `edit_note` for incremental changes; `write_note` only for new notes or with `overwrite=True`

## Relations

- implements [[Knowledge]]
- relates_to [[Workflow]]
- part_of [[Agents]]

## Before work

**Always search Basic Memory first** for any repo knowledge query — before reading files, running commands, or making changes.

Use, in order:

1. Basic Memory search
2. `rg` over `knowledge/`
3. source inspection

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

### Note structure

Use this structure when creating or updating notes:

```markdown
# Title

## Context
Background information

## Observations
- [category] Fact with #tags
- [category] Another fact

## Relations
- relation_type [[Exact Entity Title]]
```

Categories: `[idea]`, `[decision]`, `[fact]`, `[technique]`, `[requirement]`

Relation types: `relates_to`, `implements`, `requires`, `extends`, `part_of`, `contrasts_with`

### Building rich graphs

- Include 3-5 observations per note
- Include 2-3 relations per note
- Use meaningful categories and relation types
- Search before creating to avoid duplicates:
  ```
  results = search_notes(query="topic")
  # Use exact titles in [[WikiLinks]]
  ```
- Use forward references for entities that don't exist yet — they resolve when the target is created
- Use `build_context(url="memory://path", depth=2)` to traverse the knowledge graph and find related notes
- Prefer `edit_note` for updates; use `write_note` only for new notes or with `overwrite=True`

### Recording context

Ask permission before saving discussions to memory:
> "Would you like me to save our discussion about [topic] to Basic Memory?"

Confirm when done:
> "I've saved our discussion to Basic Memory."

Record:
- Decisions and rationales
- Important discoveries
- Action items and plans
- Connected topics

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
