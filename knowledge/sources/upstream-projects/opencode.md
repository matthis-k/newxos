---
id: source-opencode
type: source
title: OpenCode
status: active
tags:
- source
- opencode
links:
- sources-index
- agents-opencode
updated: 2026-05-11
permalink: newxos/sources/upstream-projects/opencode
---

# OpenCode

Interactive CLI assistant for software engineering tasks.

## Observations

- [fact] Upstream docs: <https://opencode.ai>; config schema: <https://opencode.ai/docs/config/>
- [technique] Wrapped via `nix-wrapper-modules` in `modules/opencode.nix`
- [fact] MCP servers configured for GitHub, NixOS metadata, and Basic Memory
- [fact] Skills loaded from `configs/opencode/skills/`

## Relations

- relates_to [[sources-index]]
- relates_to [[agents-opencode]]

## Upstream

- Docs: <https://opencode.ai>
- Config schema: <https://opencode.ai/docs/config/>

## Usage in this repo

- Wrapped via `nix-wrapper-modules` in `modules/opencode.nix`.
- MCP servers configured for GitHub, NixOS metadata, and Basic Memory.
- Skills loaded from `configs/opencode/skills/`.
