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
updated: 2026-05-25
permalink: newxos/sources/upstream-projects/opencode
---

# OpenCode

Interactive CLI assistant for software engineering tasks.

## Observations

- [fact] Upstream docs: <https://opencode.ai>; config schema: <https://opencode.ai/docs/config/>
- [technique] Repo integration is owned by `modules/dev/opencode.nix` and `configs/opencode/`
- [decision] Keep exact providers, MCP server definitions, skill lists, and auth wiring in source files
- [fact] Upstream config schema should be checked before changing wrapper settings

## Relations

- relates_to [[sources-index]]
- relates_to [[agents-opencode]]

## Upstream

- Docs: <https://opencode.ai>
- Config schema: <https://opencode.ai/docs/config/>

## Repo Usage Index

- Wrapper and generated settings: `modules/dev/opencode.nix`.
- Repo-owned OpenCode assets: `configs/opencode/`.
- Agent workflow guidance: `knowledge/agents/`.
- Exact provider, model, MCP, and auth details belong in source.

## Local Provider Notes

- Local model provider wiring, if enabled, belongs in `modules/dev/opencode.nix`.
- Read source for current endpoint, provider package, and model aliases.
- Related local LLM ownership: [[Local LLM and TTS setup]].

Relations:
- relates_to [[Local LLM and TTS setup]]
