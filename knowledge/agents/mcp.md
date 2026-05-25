---
id: agents-mcp
type: concept
title: MCP servers
status: active
tags:
- agents
- mcp
links:
- agents-index
- agents-opencode
- agents-basic-memory
updated: 2026-05-25
permalink: newxos/agents/mcp
---

# MCP servers

Model Context Protocol servers provide tool access to agents.

## Observations

- [fact] MCP server wiring for OpenCode is owned by `modules/dev/opencode.nix`
- [decision] Keep exact server names, commands, environment variables, and enablement in source
- [technique] Use this note to route conceptual MCP work to the OpenCode wrapper and related agent docs

## Relations

- relates_to [[agents-index]]
- relates_to [[agents-opencode]]
- relates_to [[agents-basic-memory]]

## Ownership

- Server definitions: `modules/dev/opencode.nix`.
- Repo-owned skill/config assets: `configs/opencode/`.
- Agent-facing workflow rules: `knowledge/agents/` and `AGENTS.md`.

## Adding a server

Add server wiring in `modules/dev/opencode.nix`. Keep tokens and command details out of memory unless they are generic placement rules.

Document only durable decisions here, such as why a server belongs in the default wrapper or why a class of server should stay opt-in.

## Related

- [[agents-opencode]]
- [[agents-basic-memory]]
