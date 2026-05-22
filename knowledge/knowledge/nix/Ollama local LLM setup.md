---
title: Ollama local LLM setup
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
updated: 2026-05-22
---

# Ollama local LLM setup

## Context

Local LLM inference is configured on the desktop host using Ollama with CUDA acceleration for the NVIDIA RTX 5060 GPU.

## Observations

- [fact] Ollama service uses `ollama-cuda` package for NVIDIA GPU acceleration
- [fact] Two models are loaded: `qwen2.5:7b` (general purpose) and `dolphin-mistral:7b` (uncensored)
- [fact] Web UI frontend provided by `open-webui` package with TTS support and rich features
- [technique] CUDA support enabled globally via `nixpkgs.config.cudaSupport = true`
- [requirement] `allowUnfree = true` required for CUDA runtime libraries

## Relations

- implements [[Hardware]]
- relates_to [[Flake Structure]]
- part_of [[Desktop Host]]

## Configuration

Module location: `modules/desktop/ollama.nix`

This module is only imported by the desktop host, not the laptop.

Key settings:
- Service: `services.ollama.enable = true`
- Package: `ollama-cuda` for RTX 5060
- Models: `qwen2.5:7b`, `dolphin-mistral:7b`
- Web UI: `services.open-webui.enable = true` (port 3000, TTS supported)
- Firewall: `openFirewall = true` handles port 3000 automatically

## Model Selection

- **qwen2.5:7b**: Balanced Qwen model for general tasks, fits well in RTX 5060 VRAM
- **dolphin-mistral:7b**: Uncensored variant based on Mistral architecture

## Access

User `matthisk` added to `ollama` group for direct CLI access.

Web UI accessible at `http://localhost:3000`. Open WebUI includes built-in TTS settings in Admin panel (Settings → Audio → Text-to-Speech).