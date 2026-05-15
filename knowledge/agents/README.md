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
updated: 2026-05-11
permalink: newxos/agents/readme
---

# Agents

This folder describes the agent tooling and workflows used in this repo.

## Observations

- [fact] OpenCode is wrapped as a nix-wrapper-modules package with MCP servers configured
- [technique] Basic Memory provides semantic knowledge graph indexing for agent context
- [decision] MCP servers configured for GitHub, NixOS metadata, and Basic Memory access
- [fact] Skills loaded from `configs/opencode/skills/` for specialized agent behaviors

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
