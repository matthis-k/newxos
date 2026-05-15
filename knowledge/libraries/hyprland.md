---
title: hyprland
type: note
permalink: newxos/libraries/hyprland
---

# hyprland

Hyprland (0.55+) provides the graphical desktop session used by this repo. Since 0.55, configuration uses Lua instead of the legacy hyprlang syntax.

## Observations

- [fact] Upstream flake input provides compositor packages; NixOS module enables session and supporting packages
- [technique] Keep `configs/hypr/hyprland.lua` as hand-written root config; `configs/hypr/monitors.lua` as logic layer for Nix-provided monitor imports
- [decision] Prefer editing Lua config tree instead of generating whole Hyprland config from Nix
- [fact] Nix-generated values go into `~/.config/hypr/nix-import.lua` instead of cluttering hand-written root config
- [fact] Home Manager's Hyprland plugin option generates `hyprland.conf` entries, not suitable for Lua-native root config

## Relations

- relates_to [[Flake Structure]]
- relates_to [[Wrapped Programs And Generated Config]]

## What It Does Here

- The upstream flake input provides the compositor packages.
- The NixOS module enables the session and supporting packages.
- Home Manager copies the hand-written `configs/hypr/` tree into `~/.config/hypr`.
- Screenshot helpers use `grimblast` for capture. `screen-shot` selects `region`, `region-direct`, `output`, or `window`; `satty` is separate for annotation, and `screen-read-region` uses `tesseract` OCR.
- Nix-generated values should go into `~/.config/hypr/nix-import.lua` instead of cluttering the hand-written root config.
- Repo monitor definitions flow through `newxos.hyprland.monitors`, into `nix-import.lua`, and are applied by `configs/hypr/monitors.lua`.

## Basics

- Keep `configs/hypr/hyprland.lua` as the hand-written root config.
- Keep `configs/hypr/monitors.lua` as the logic layer for Nix-provided monitor imports.
- Keep structured binds in `configs/hypr/keybinds.lua`.
- Prefer `grimblast` when you want Hyprland-native capture with readable shell glue. Keep one `screen-shot` entrypoint with a mode argument instead of duplicating tiny wrapper binaries for each capture target.
- Prefer editing the Lua config tree instead of generating the whole Hyprland config from Nix.
- Keep repo-root `.luarc.json` pointed at `/usr/share/hypr/stubs` so Lua LSP can resolve `hl` and Hyprland stubs while editing `configs/hypr/*.lua`.
- Related reading: [[Flake Structure]], [[Wrapped Programs And Generated Config]].

## Upstream Overview (0.55+ Lua config)

### Config location

- `~/.config/hypr/hyprland.lua` (or `$XDG_CONFIG_HOME/hypr/hyprland.lua`)
- The old hyprlang `.conf` syntax is deprecated since 0.55; use the 0.54 wiki for legacy configs.

### Lua config structure

- Config is a Lua script executed by Hyprland's embedded interpreter.
- Uses `hl` module for Hyprland-specific functions (dispatchers, config setters, binds).
- `require()` loads other Lua files for modular config organization.
- Standard Lua features (tables, functions, loops, conditionals) are available for dynamic config generation.

### Core configuration areas

**Monitors** — `hl.monitor()` or equivalent for per-monitor resolution, position, refresh rate, scale, transform. `auto` keyword for auto-detected settings. Workspace assignment per monitor.

**Binds** — `hl.bind()` or equivalent for key combinations. Modifiers: `SUPER`, `CTRL`, `ALT`, `SHIFT`. Bind modes for layered keymaps. Repeat, release, and non-consuming variants. Dispatcher invocation from binds.

**Dispatchers** — actions triggered by binds or `hyprctl`. Common dispatchers: `exec`, `togglefloating`, `fullscreen`, `movefocus`, `movewindow`, `workspace`, `splitratio`, `resizeactive`, `pin`, `killactive`, `exit`. Custom dispatchers via plugins.

**Window rules** — per-application rules for floating, pinning, sizing, workspace assignment, animation overrides, opacity, rounding. Match by initial title, class, or regex.

**Workspace rules** — per-workspace defaults for layout, gaps, animations. Default workspace naming and monitor binding.

**Layouts** — Dwindle (binary tree), Master (main-stack), Scrolling (carousel), Monocle (single-window). Per-layout options for split ratios, special scale, orientation. Custom layouts via plugins.

**Animations** — enabled/disabled globally, per-animation type (windows, borders, workspaces, layers, custom). Bezier curve definitions. Speed, style, and override settings.

**Devices** — input device configuration (keyboard layout, repeat rate, touchpad natural scroll, tap-to-click, mouse acceleration). Per-device overrides.

**Decorations** — rounding, shadows, blurring, borders, opacity. Active/inactive border colors. Blur passes and size.

**General** — layout selection, gaps, resize mode, hover behavior, cursor settings.

**Autostart** — `exec-once` and `exec` equivalents for startup commands. Daemon and background process launching.

**Environment variables** — `env` declarations for Hyprland and child processes. Common ones: `NIXOS_OZONE_WL`, `XDG_SESSION_TYPE`, `XCURSOR_SIZE`, `QT_QPA_PLATFORM`, `GDK_BACKEND`, `MOZ_ENABLE_WAYLAND`, `ELECTRON_OZONE_PLATFORM_HINT`, `CLUTTER_BACKEND`, `LIBVA_DRIVER_NAME`.

### hyprctl

- Runtime control via `hyprctl` CLI: `hyprctl dispatch`, `hyprctl keyword`, `hyprctl getoption`, `hyprctl monitors`, `hyprctl workspaces`, `hyprctl clients`, `hyprctl devices`, `hyprctl reload`, `hyprctl activewindow`, `hyprctl activeworkspace`.
- JSON output with `-j` flag for scripting.
- Socket-based IPC; also available via `hyprctl` events (`hyprctl event` or socket subscription).

### Plugins

- Custom layouts, decorations, and functionality via shared libraries.
- Loaded via `plugin` directive in config.
- Hyprspace, Hyprexpo, and others extend base functionality.

### XWayland

- Enabled by default for X11 app compatibility.
- Some X11 apps need environment variable hints for proper Wayland behavior.
- Force XWayland or native Wayland per-app via window rules.

### Gestures

- Touchpad swipe/pinch gestures for workspace switching, overview, and custom actions.
- Configurable gesture bindings with modifier combinations.

### Tearing

- Per-window and per-monitor tearing control for reduced latency.
- Fullscreen and windowed tearing variants.

### Performance

- Rendering pipeline options, VRR (adaptive sync), direct scanout.
- DRM vs X11 backend considerations.
- GPU-specific tuning for NVIDIA and AMD.

### Short Example (Lua)

```lua
-- Monitor definition
hl.monitor("DP-1", "2560x1440@144,auto,1")
hl.monitor("HDMI-A-1", "1920x1080@60,auto,1")

-- Keybinds
hl.bind("SUPER", "Return", "exec", "kitty")
hl.bind("SUPER", "Q", "killactive")
hl.bind("SUPER", "F", "fullscreen")

-- Window rule
hl.windowrule("float", "title:(.*)(File Transfer)(.*)")
hl.windowrule("size 800 600", "class:org.gnome.Calculator")

-- Environment
hl.env("NIXOS_OZONE_WL", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
```

### Helpful Docs

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
