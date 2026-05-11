---
title: stylix
type: note
permalink: newxos/libraries/stylix
---

# stylix

Stylix is the repo's theme backbone.

## What It Does Here

- Holds the repo-owned semantic palette in `modules/stylix/stylix.nix`.
- Derives the Base16 scheme from that palette.
- Feeds the same palette into custom Kitty and Fish theme generation.
- Feeds the same palette into a repo-owned Zen Browser Catppuccin-style theme layer.
- Uses the `catppuccin-breeze-cursors` flake input and selects its packaged blue cursor theme through Home Manager pointer cursor settings.
- Uses Stylix icon wiring with `Papirus-Dark` so GTK and Qt share one icon theme.
- Passes the selected palette from NixOS into Home Manager through shared modules.

## Basics

- Keep custom theme logic in `modules/stylix/`.
- Prefer generating small theme fragments from Nix and importing them from program config.
- This repo disables some built-in Stylix targets when a repo-owned generated theme is the better fit.
- Related reading: [Flake Structure](../flake-structure.md#modulesstylix), [Wrapped Programs And Generated Config](../patterns/wrapped-programs.md).

## Short Example

```nix
stylix = {
  enable = true;
  base16Scheme = mkBase16Scheme fullPalette;
  homeManagerIntegration.autoImport = false;
};
```

```conf
include ~/.config/kitty/stylix-theme.auto.conf
```

## Helpful Docs

- Main docs: `https://nix-community.github.io/stylix/`
- Installation: `https://nix-community.github.io/stylix/installation.html`
- Configuration: `https://nix-community.github.io/stylix/configuration.html`
- Kitty target: `https://nix-community.github.io/stylix/options/modules/kitty.html`
- Fish target: `https://nix-community.github.io/stylix/options/modules/fish.html`
- Catppuccin fish reference: `https://github.com/catppuccin/fish`

## Known Quirks Here

- `stylix.homeManagerIntegration.autoImport` stays off so the repo's explicit Home Manager entrypoint remains the one source of truth.
- Built-in Kitty and Fish targets are disabled because the repo uses richer Catppuccin-shaped generated output there.
- Built-in Zen Browser CSS is disabled because the generic Base16 target lost too much full-palette intent for contrast-sensitive UI like selected tabs and urlbar suggestions.
- Cursor theme comes from the upstream cursor flake's packaged blue output instead of copying raw theme files inside this repo.
- GTK and Qt stay on Stylix-managed theming; repo only overrides app theming when Stylix target is not enough.
- If you want a custom theme tweak that should apply across multiple apps, start in `modules/stylix/`, not inside a single app config.