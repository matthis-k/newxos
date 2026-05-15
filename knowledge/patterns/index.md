---
title: index
type: note
permalink: newxos/patterns/index
---

# Patterns

Important repo composition patterns.

## Observations

- [fact] Five patterns documented: dendritic modules, scope boundaries, host/user layout, wrapped programs, QuickShell design
- [decision] Use these pages for repo conventions; library pages for upstream behavior; [[Encountered Issues]] for repeated mistakes

## Relations

- part_of [[Knowledge]]
- relates_to [[Encountered Issues]]

## Index

- [[dendritic-modules]]: small feature-focused modules instead of one central registry.
- [[Scope Boundaries And Per-System Access]]: how to move between top-level flake scope, `perSystem`, and NixOS or Home Manager modules.
- [[Host And User Layout]]: how concrete hosts, shared system modules, and user modules are arranged.
- [[Wrapped Programs And Generated Config]]: when config belongs in wrappers, in `configs/`, or in generated imports.
- [[quickshell-design]]: flat design, animations, and Catppuccin palette usage for QuickShell UI.

## Notes

- Use these pages for repo conventions.
- Use library pages for upstream behavior.
- Use [[Encountered Issues]] for repeated mistakes.
