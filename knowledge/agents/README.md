---
id: agents-index
type: index
title: Agents
status: active
tags:
- agents
links:
- agents-opencode
- agents-basic-memory
- agents-workflows
updated: 2026-05-25
permalink: newxos/agents/readme
---

# Agents

This folder describes the agent tooling and workflows used in this repo.

## Observations

- [fact] Agent tooling ownership is indexed here; exact wrapper and MCP settings belong in source
- [technique] Basic Memory provides semantic knowledge graph indexing for agent context
- [decision] Keep conceptual workflow rules in `knowledge/agents/` and concrete OpenCode assets in `configs/opencode/`
- [fact] OpenCode wrapper wiring lives in `modules/dev/opencode.nix`

## Relations

- part_of [[Knowledge]]
- relates_to [[OpenCode]]
- relates_to [[Workflow]]

## Core notes

- [[agents-opencode]]
- [[agents-basic-memory]]
- [[agents-mcp]]
- [[agents-caveman-skill]]
- [[agents-workflows]]
