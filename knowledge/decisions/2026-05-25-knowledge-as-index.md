---
id: decision-2026-05-25-knowledge-as-index
type: decision
title: Keep knowledge as project index and decision memory
status: accepted
tags:
- memory
- knowledge
- workflow
- decision
links:
- agent-rules
- decision-2026-05-11-use-basic-memory
- architecture-index
updated: 2026-05-25
permalink: newxos/decisions/2026-05-25-knowledge-as-index
---

# Keep Knowledge As Project Index And Decision Memory

## Context

Some knowledge notes had started to duplicate details that should be read from Nix modules or application config files. That makes memory feel arbitrary and creates drift risk when source files change.

## Observations

- [decision] Treat `knowledge/` as indirection from concepts to source locations, ownership rules, and durable decisions
- [requirement] Do not mirror exact Nix declarations, package lists, generated settings, or application config values in knowledge notes
- [technique] Put minor implementation rationale beside the relevant code as concise comments
- [fact] Library references and repo-specific upstream integration notes remain useful knowledge content

## Decision

Knowledge entries should answer: "when searching for this concept, where should I look, what owns it, and what durable decisions constrain changes?"

Use source files as the source of truth for exact behavior. Use nearby source comments for small fragile details, such as why one option value is needed to integrate with another component.

## Consequences

- Agents should search memory first to find the right area, then inspect source for exact behavior.
- Knowledge notes should stay concise and structural instead of documenting every current setting.
- Durable decisions, placement rules, recurring issues, and upstream references remain in `knowledge/`.
- Notes that mirror source should be rewritten into concept indexes or removed when no longer useful.

## Relations

- implements [[Agent rules]]
- relates_to [[Use Basic Memory for agent knowledge]]
- relates_to [[Architecture]]
