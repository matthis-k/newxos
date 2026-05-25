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
- [technique] Wrapped via `nix-wrapper-modules` in `modules/dev/opencode.nix`
- [fact] MCP servers configured for GitHub, NixOS metadata, and Basic Memory
- [fact] Skills loaded from `configs/opencode/skills/`

## Relations

- relates_to [[sources-index]]
- relates_to [[agents-opencode]]

## Upstream

- Docs: <https://opencode.ai>
- Config schema: <https://opencode.ai/docs/config/>

## Usage in this repo

- Wrapped via `nix-wrapper-modules` in `modules/dev/opencode.nix`.
- MCP servers configured for GitHub, NixOS metadata, and Basic Memory.
- Skills loaded from `configs/opencode/skills/`.

## Local Ollama Provider

- [fact] OpenCode config includes an `ollama` provider via `@ai-sdk/openai-compatible`
- [fact] Local provider endpoint is `http://localhost:11434/v1`
- [fact] Local coding model exposed in OpenCode is `ollama/qwen2.5-coder:7b`
- [technique] Use `/models` in OpenCode to select `Ollama (local)` / `Qwen2.5 Coder 7B (local)`

Relations:
- relates_to [[Local LLM and TTS setup]]
