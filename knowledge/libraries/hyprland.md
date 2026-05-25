---
title: hyprland
type: note
permalink: newxos/libraries/hyprland
---

# hyprland

Hyprland (0.55+) provides the graphical desktop session used by this repo. Since 0.55, configuration uses Lua instead of the legacy hyprlang syntax.

## Observations

- [fact] Hyprland session ownership is split between modules for package/session wiring and `configs/hypr/` for hand-written Lua config
- [technique] Keep `configs/hypr/hyprland.lua` as hand-written root config; `configs/hypr/monitors.lua` as logic layer for Nix-provided monitor imports
- [decision] Prefer editing Lua config tree instead of generating whole Hyprland config from Nix
- [fact] Nix-generated values go into the wrapper-generated `nix-import.lua` instead of cluttering hand-written root config
- [fact] Home Manager's Hyprland plugin option generates `hyprland.conf` entries, not suitable for Lua-native root config

## Relations

- relates_to [[Flake Structure]]
- relates_to [[Wrapped Programs And Generated Config]]

## What It Does Here

- Upstream flake input and NixOS/Home Manager wiring live in modules.
- Hand-written Lua config lives in `configs/hypr/`.
- Helper scripts and screenshot behavior belong in the module source that exposes them.
- Nix-generated values should go into the wrapper-generated `nix-import.lua` instead of cluttering the hand-written root config.
- Host-specific monitor definitions belong in each host's `programs.hyprland.package` wrapper override, where they become `nix-import.lua` values applied by `configs/hypr/monitors.lua`.

## Basics

- Keep `configs/hypr/hyprland.lua` as the hand-written root config.
- Keep `configs/hypr/monitors.lua` as the logic layer for Nix-provided monitor imports.
- Keep structured binds in `configs/hypr/keybinds.lua`.
- Prefer `grimblast` when you want Hyprland-native capture with readable shell glue. Keep one `screen-shot` entrypoint with a mode argument instead of duplicating tiny wrapper binaries for each capture target.
- Prefer editing the Lua config tree instead of generating the whole Hyprland config from Nix.
- Keep repo-root `.luarc.json` pointed at `/usr/share/hypr/stubs` so Lua LSP can resolve `hl` and Hyprland stubs while editing `configs/hypr/*.lua`.
- Related reading: [[Flake Structure]], [[Wrapped Programs And Generated Config]].

## Helpful Docs

- Wiki home: `https://wiki.hypr.land/`
- Version selector: `https://wiki.hypr.land/version-selector/`
- Getting started: `https://wiki.hypr.land/Getting-Started/`
- Configuring start (Lua): `https://wiki.hypr.land/Configuring/Start/`
- Basics (variables, monitors, binds, dispatchers, rules, autostart): `https://wiki.hypr.land/Configuring/Basics/`
- Layouts (dwindle, master, scrolling, monocle, custom): `https://wiki.hypr.land/Configuring/Layouts/`
- Advanced (animations, gestures, devices, tearing, permissions, hyprctl, notifications, plugins, XWayland, env vars, multi-GPU, performance): `https://wiki.hypr.land/Configuring/Advanced-and-Cool/`
- Troubleshooting: `https://wiki.hypr.land/Troubleshooting/`
- Upstream repo: `https://github.com/hyprwm/Hyprland`

## Known Quirks

- Home Manager's Hyprland plugin option generates `hyprland.conf` entries, so it is not the right place for this repo's Lua-native root config.
- If a value really needs to come from Nix, generate a small imported Lua file instead of rewriting the hand-written config style.
- The `.luarc.json` in the repo root must point at the correct Hyprland stubs path for Lua LSP to work; this path varies by installation method.
