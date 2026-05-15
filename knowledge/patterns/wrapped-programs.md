---
title: wrapped-programs
type: note
permalink: newxos/patterns/wrapped-programs
---

# Wrapped Programs And Generated Config

This repo prefers wrapped programs when it owns opinionated config.

## Observations

- [decision] Use wrapper packages when a program should ship with repo-owned config
- [technique] Keep hand-written user-facing config in `configs/`; generate small derived fragments from Nix and import from hand-written config
- [fact] Put custom nix-wrapper-modules wrapper definitions in `modules/wrappers/`
- [decision] If a program already has a repo wrapper, prefer using it over wiring the raw package directly

## Relations

- relates_to [[nix-wrapper-modules]]
- relates_to [[stylix]]
- relates_to [[hyprland]]

## What It Means Here

- Use wrapper packages when a program should ship with repo-owned config.
- Keep hand-written user-facing config in `configs/` when direct editing still matters.
- Generate small derived fragments from Nix and import them from the hand-written config when that keeps ownership clear.
- Related reading: [[nix-wrapper-modules]], [[stylix]], [[hyprland]].

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

- Put custom nix-wrapper-modules wrapper definitions in `modules/wrappers/`.
- Put hand-written app config in `configs/`.
- Put feature-specific install/service wiring in the relevant feature module, consuming wrapper packages via `withSystem` and `self'.packages`.
- Put shared theme generation in `modules/stylix/`, then import the generated result.
- If a program already has a repo wrapper, prefer using it over wiring the raw package directly.
- Avoid checking in generated config when the module can create it for you.
