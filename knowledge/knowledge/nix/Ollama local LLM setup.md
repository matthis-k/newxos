---
title: Local LLM and TTS setup
type: note
permalink: newxos/ollama-local-llm
id: ollama-local-llm
status: active
tags:
- nix
- ai
- desktop
links:
- hardware-index
- architecture-index
updated: 2026-05-23
---

# Local LLM and TTS setup

## Context
Local LLM and TTS support is owned by the desktop LLM module. This note is an index to the owning files and durable constraints; read source for current models, ports, containers, users, and service options.
## Observations
- [fact] `modules/desktop/llm-server.nix` owns local LLM, Open WebUI, Kokoro-FastAPI TTS wiring, and related containers
- [decision] Keep model choices, service ports, container image names, and environment values in the module source
- [requirement] Kokoro-FastAPI is the current local TTS backend for live playback; keep Open WebUI pointed at its OpenAI-compatible `/v1` endpoint and set `AUDIO_TTS_SPLIT_ON` deliberately for the desired latency/quality tradeoff
- [technique] Use this note to find the owner, then inspect source for exact Ollama, Open WebUI, and TTS behavior
## Relations

- implements [[Hardware]]
- relates_to [[Flake Structure]]
- part_of [[Desktop Host]]

## Ownership

- Module owner: `modules/desktop/llm-server.nix`
- Host imports and enablement live under the concrete desktop host in `modules/hosts/`.
- Kokoro-FastAPI uses the OpenAI-compatible `/v1` speech endpoint; exact image, port, model, voice, split mode, and API key defaults live in the module.

## Durable Rules

- Do not duplicate model lists or endpoint values here; they drift quickly.
- Record recurring failures in `knowledge/issues/` or `knowledge/encountered_issues.md` and point back to this module.
- Keep small comments beside fragile environment values in `modules/desktop/llm-server.nix`.

## Related Issues

- [[Encountered Issues]] records Open WebUI TTS persistence and GPU container compatibility gotchas.
