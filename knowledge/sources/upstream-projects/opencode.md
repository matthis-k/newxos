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

## Upstream

- Docs: <https://opencode.ai>
- Config schema: <https://opencode.ai/docs/config/>

## Usage in this repo

- Wrapped via `nix-wrapper-modules` in `modules/opencode.nix`.
- MCP servers configured for GitHub, NixOS metadata, and Basic Memory.
- Skills loaded from `configs/opencode/skills/`.