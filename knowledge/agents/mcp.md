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
updated: 2026-05-11
permalink: newxos/agents/mcp
---

# MCP servers

Model Context Protocol servers provide tool access to agents.

## Observations

- [fact] Three MCP servers configured: GitHub, NixOS, and Basic Memory
- [technique] Add servers to `settings.mcp` in `modules/opencode.nix`
- [fact] Servers run in local `stdio` mode

## Relations

- relates_to [[agents-index]]
- relates_to [[agents-opencode]]
- relates_to [[agents-basic-memory]]

## Configured servers

| Server | Purpose |
|--------|---------|
| `github` | GitHub API access (issues, PRs, repos) |
| `nixos` | NixOS/Home Manager/darwin option and package truth |
| `basic-memory` | Local Markdown project memory search |

## Adding a server

Add to `settings.mcp` in `modules/opencode.nix`:

```nix
mcp = {
  name = {
    type = "local";
    command = [ (lib.getExe pkgs.some-tool) ];
    enabled = true;
  };
};
```

## Related

- [[agents-opencode]]
- [[agents-basic-memory]]
