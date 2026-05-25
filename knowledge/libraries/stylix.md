---
title: stylix
type: note
permalink: newxos/libraries/stylix
---

# stylix

Stylix is the repo's theme backbone.

## Observations

- [fact] Holds repo-owned semantic palette in `modules/theming/stylix.nix`; derives Base16 scheme from that palette
- [technique] Feed same palette into custom Kitty, Fish, Zen Browser, and QuickShell JSON theme generation
- [decision] Disable some built-in Stylix targets when repo-owned generated theme is better fit
- [fact] Read `modules/theming/` for exact Stylix targets, cursor choices, and generated fragments

## Relations

- relates_to [[Flake Structure]]
- relates_to [[Wrapped Programs And Generated Config]]
- relates_to [[quickshell-design]]

## What It Does Here

- Holds the repo-owned semantic palette in `modules/theming/stylix.nix`.
- Derives the Base16 scheme from that palette.
- Feeds the same palette into custom Kitty and Fish theme generation.
- Feeds the same palette into a repo-owned Zen Browser Catppuccin-style theme layer.
- Generates a JSON palette file for QuickShell to read at runtime.
- Cursor, icon, GTK, Qt, and Home Manager integration details belong in `modules/theming/` and shared modules.

## Basics

- Keep custom theme logic in `modules/theming/`.
- Prefer generating small theme fragments from Nix and importing them from program config.
- This repo disables some built-in Stylix targets when a repo-owned generated theme is the better fit.
- QuickShell reads the generated JSON palette at runtime; see [[quickshell-design]].
- Related reading: [[Flake Structure]], [[Wrapped Programs And Generated Config]].

## Helpful Docs

- Main docs: `https://nix-community.github.io/stylix/`
- Installation: `https://nix-community.github.io/stylix/installation.html`
- Configuration: `https://nix-community.github.io/stylix/configuration.html`
- Kitty target: `https://nix-community.github.io/stylix/options/modules/kitty.html`
- Fish target: `https://nix-community.github.io/stylix/options/modules/fish.html`
- Catppuccin fish reference: `https://github.com/catppuccin/fish`

## Known Quirks

- `stylix.homeManagerIntegration.autoImport` stays off so the repo's explicit Home Manager entrypoint remains the one source of truth.
- Built-in Kitty and Fish targets are disabled because the repo uses richer Catppuccin-shaped generated output there.
- Built-in Zen Browser CSS is disabled because the generic Base16 target lost too much full-palette intent for contrast-sensitive UI like selected tabs and urlbar suggestions.
- Cursor theme comes from the upstream cursor flake's packaged blue output instead of copying raw theme files inside this repo.
- GTK and Qt stay on Stylix-managed theming; repo only overrides app theming when Stylix target is not enough.
- If you want a custom theme tweak that should apply across multiple apps, start in `modules/theming/`, not inside a single app config.

## Bootloader Theming

## Observations

- [decision] Repo font defaults belong in the Stylix module, not host boot modules
- [technique] Stylix's GRUB target derives the GRUB `.pf2` font from `stylix.fonts.monospace` when GRUB is enabled

## Relations

- relates_to [[Host And User Layout]]
- relates_to [[Hardware]]
