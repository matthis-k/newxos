# OpenCode And MCP

This repo exposes a wrapped `opencode` package with MCP servers preconfigured.

## What It Does Here

- Exposes `nix run "path:$PWD#opencode"` as the repo-managed assistant package.
- Preconfigures `mcp-nixos` and GitHub MCP in local `stdio` mode.
- Allows the wrapped assistant to read trusted paths under `~/.config/` and `/nix/store/`.
- Installs the `caveman` skill into `~/.config/opencode/skills/` through Home Manager.
- Gives the assistant a stable repo-local setup instead of depending on ad hoc machine state.

## Basics

- Use `nixos_nix` or the packaged MCP server for upstream Nix package and option facts.
- GitHub MCP expects `GITHUB_PERSONAL_ACCESS_TOKEN` in the environment.
- The repo provisions that token from a `sops`-managed secret rather than relying on `gh` auth state.
- Related reading: [sops-nix](sops-nix.md), [Workflow](../workflow.md#secrets-and-data-care).

## Helpful Docs

- OpenCode config docs: `https://opencode.ai/docs/config/`
- OpenCode rules docs: `https://opencode.ai/docs/rules/`
- OpenCode config schema: `https://opencode.ai/config.json`
- OpenCode upstream: `https://github.com/anomalyco/opencode`
- `mcp-nixos`: `https://github.com/utensils/mcp-nixos`
- GitHub MCP server: `https://github.com/github/github-mcp-server`

## Known Quirks Here

- Do not print or inspect the GitHub token when debugging auth wiring.
- Verify executable paths and package exposure through `nix flake show "path:$PWD"` when changing the wrapper.
