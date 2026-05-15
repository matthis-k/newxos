---
id: source-catppuccin-zen-browser
type: source
title: Catppuccin Zen Browser theme
status: active
tags:
- source
- catppuccin
- zen-browser
links:
- sources-index
- theming-zen-browser
- theming-catppuccin
updated: 2026-05-11
permalink: newxos/sources/upstream-projects/catppuccin-zen-browser
---

# Catppuccin Zen Browser theme

Catppuccin-style theme for Zen Browser.

## Observations

- [fact] Upstream repo: <https://github.com/catppuccin/zen-browser>
- [decision] Repo generates its own Zen Browser CSS from `config.stylix.fullPalette.colors` to preserve semantic contrast intent
- [fact] Generic Base16 slot mapping loses contrast for contrast-sensitive UI

## Relations

- relates_to [[sources-index]]
- relates_to [[issue-zen-browser-chrome-not-themed]]

## Upstream

- Repo: <https://github.com/catppuccin/zen-browser>

## Usage in this repo

The repo generates its own Zen Browser CSS from `config.stylix.fullPalette.colors` to preserve semantic contrast intent that generic Base16 slot mapping loses.

## Related

- [[issue-zen-browser-chrome-not-themed]]
