---
title: wrapped-programs
type: note
permalink: newxos/patterns/wrapped-programs
---

# Wrapped Programs And Generated Config

This repo prefers wrapped programs when it owns opinionated config.

## What It Means Here

- Use wrapper packages when a program should ship with repo-owned config.
- Keep hand-written user-facing config in `configs/` when direct editing still matters.
- Generate small derived fragments from Nix and import them from the hand-written config when that keeps ownership clear.
- Related reading: [nix-wrapper-modules](../libraries/nix-wrapper-modules.md), [stylix](../libraries/stylix.md), [hyprland](../libraries/hyprland.md).

## Short Examples

```conf
include ~/.config/kitty/stylix-theme.auto.conf
```

```nix
xdg.configFile."hypr/nix-import.lua".text = ''
  return {}
'';
```

## Practical Rules

- Put wrapper logic in `modules/`.
- Put hand-written app config in `configs/`.
- Put shared theme generation in `modules/stylix/`, then import the generated result.
- If a program already has a repo wrapper, prefer using it over wiring the raw package directly.
- Avoid checking in generated config when the module can create it for you.