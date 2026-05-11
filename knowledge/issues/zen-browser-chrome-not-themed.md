---
id: issue-zen-browser-chrome-not-themed
type: issue
title: Zen Browser chrome not themed
status: active
tags:
- issue
- zen-browser
- theming
- catppuccin
links:
- issues-index
- theming-zen-browser
- theming-catppuccin
updated: 2026-05-11
permalink: newxos/issues/zen-browser-chrome-not-themed
---

# Zen Browser chrome not themed

## Problem

Zen Browser's chrome (UI shell) does not pick up the repo's Catppuccin-style theme.

## Symptoms

- Browser content area is themed correctly.
- Title bar, tabs, and URL bar remain unthemed or use default colors.

## Cause

Zen Browser requires `userChrome.css` to theme its chrome. Stylix does not generate this by default for Zen.

## Fix

Generate repo-owned Zen Browser CSS from `config.stylix.fullPalette.colors` and install it as `userChrome.css`.

## Rule

When app theme needs more nuance than Base16 slots provide, disable built-in target CSS and generate repo-owned full-palette target under `modules/stylix/`.

## Related

- [[issue-prefers-color-scheme-dark]]
- [[task-fix-zen-catppuccin-chrome]]