---
id: agents-opencode
type: concept
title: OpenCode integration
status: active
tags:
- agents
- opencode
- mcp
links:
- agents-basic-memory
- agents-mcp
updated: 2026-05-25
permalink: newxos/agents/opencode
---

# OpenCode integration

This repo exposes OpenCode through Nix so agent tooling is reproducible. This note indexes the owning files and durable rules; read source for current settings.

## Observations

- [fact] OpenCode wrapper ownership lives in `modules/dev/opencode.nix`
- [fact] Repo-owned OpenCode assets live in `configs/opencode/`
- [technique] Use `nix run "path:$PWD#opencode"` to run the repo-managed assistant package
- [requirement] GitHub token provisioned from `sops`-managed secret, not `gh` auth state
- [decision] Keep exact MCP servers, provider aliases, trusted paths, and environment details in source

## Relations

- relates_to [[agents-basic-memory]]
- relates_to [[agents-mcp]]

## Ownership

- Wrapper and generated OpenCode settings: `modules/dev/opencode.nix`.
- Repo-owned skill sources and config fragments: `configs/opencode/`.
- Knowledge-loading rules: `AGENTS.md`, `opencode.json`, and `knowledge/agents/`.
- Secret provisioning: `modules/common/sops.nix`, user/host wiring, and [[sops-nix]].

## Configuration

- `opencode.json` controls the stable instruction entrypoints.
- `modules/dev/opencode.nix` is the source of truth for generated settings and package behavior.
- `configs/opencode/` is for repo-owned OpenCode assets, not package manager state.

## Basics

- Use `nixos_nix` or the packaged MCP server for upstream Nix package and option facts.
- GitHub MCP token environment wiring is provisioned from a `sops`-managed secret rather than relying on `gh` auth state.
- Read source for the current MCP server list and provider configuration.
- Related reading: [[sops-nix]], [[Workflow]].

## Helpful Docs

- OpenCode config docs: <https://opencode.ai/docs/config/>
- OpenCode rules docs: <https://opencode.ai/docs/rules/>
- OpenCode config schema: <https://opencode.ai/config.json>
- OpenCode upstream: <https://github.com/anomalyco/opencode>
- `mcp-nixos`: <https://github.com/utensils/mcp-nixos>
- GitHub MCP server: <https://github.com/github/github-mcp-server>

## Known Quirks

- Do not print or inspect the GitHub token when debugging auth wiring.
- Verify executable paths and package exposure through `nix flake show "path:$PWD"` when changing the wrapper.
- Keep `configs/opencode/` for repo-owned config fragments only. Do not keep `node_modules/`, `package.json`, or lockfiles there unless repo starts managing plugins explicitly.

## Auth Rules

- [requirement] Do not auto-import OpenCode provider auth for `openai` or `opencode`; provider login remains user-controlled through OpenCode
- [requirement] Keep provider secrets and OAuth tokens out of repo memory and commits unless explicitly needed as encrypted SOPS files
- [requirement] Do not print decrypted OpenCode API keys or OAuth tokens

## Relations

- relates_to [[sops-nix]]
- relates_to [[Installation]]
