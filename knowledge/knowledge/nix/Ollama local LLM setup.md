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
Local LLM inference is configured on the desktop host with Ollama CUDA acceleration, Open WebUI, and optional local OpenAI-compatible TTS through OpenedAI Speech / XTTS-v2.
## Observations
- [fact] Ollama service uses `ollama-cuda` package for NVIDIA GPU acceleration
- [fact] `modules/desktop/llm-server.nix` owns Ollama, Open WebUI, and local TTS wiring
- [fact] Default Ollama models are `qwen2.5:7b`, `qwen2.5-coder:7b`, `dolphin-mistral:7b`, and `nomic-embed-text`
- [fact] OpenedAI Speech provides local OpenAI-compatible TTS on port 8000 when `services.llm-server.enableTTS = true`
- [technique] Open WebUI TTS is configured through environment variables with `ENABLE_PERSISTENT_CONFIG=False` and `AUDIO_TTS_SPLIT_ON=punctuation`
- [requirement] `allowUnfree = true` and CUDA support are required for NVIDIA/CUDA runtime libraries
## Relations

- implements [[Hardware]]
- relates_to [[Flake Structure]]
- part_of [[Desktop Host]]

## Configuration
Module location: `modules/desktop/llm-server.nix`

This module is imported by the desktop host and exposes `services.llm-server.*` options.

Key settings:
- Ollama: `services.ollama.enable = true`, package `pkgs.ollama-cuda`, default port 11434
- Models: `qwen2.5:7b`, `qwen2.5-coder:7b`, `dolphin-mistral:7b`, `nomic-embed-text`
- Open WebUI: `services.open-webui.enable = true`, default port 3000, firewall open by default
- RAG embeddings: Open WebUI uses Ollama `nomic-embed-text`
- TTS: `openedai-speech.service` runs Docker image `openedai-speech-xtts-sm120:torchcodec` on host networking, default port 8000
- GPU container access: `hardware.nvidia-container-toolkit.enable = true` and Docker `--device nvidia.com/gpu=all` when TTS is enabled
## Model Selection
- `qwen2.5:7b`: balanced Qwen model for general tasks, fits well in RTX 5060 VRAM
- `dolphin-mistral:7b`: uncensored variant based on Mistral architecture
- `nomic-embed-text`: local embedding model for Open WebUI RAG
- `tts-1-hd`: OpenedAI Speech XTTS-v2 model for natural local TTS
- `tts-1`: OpenedAI Speech Piper model option
## Access
User `matthisk` is added to `ollama` and `docker` groups by the module.

Open WebUI is accessible at `http://localhost:3000`.

OpenedAI Speech is accessible locally at `http://localhost:8000`; direct health/docs check is `http://localhost:8000/docs`, and speech generation uses `POST /v1/audio/speech` with model `tts-1-hd` and voice `alloy` by default.