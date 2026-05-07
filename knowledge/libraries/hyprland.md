# hyprland

Hyprland provides the graphical desktop session used by this repo.

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
- Related reading: [Flake Structure](../flake-structure.md#configs), [Wrapped Programs And Generated Config](../patterns/wrapped-programs.md).

## Short Example

```nix
xdg.configFile."hypr" = {
  source = ../../configs/hypr;
  recursive = true;
};

xdg.configFile."hypr/nix-import.lua".text = ''
  return {}
'';
```

## Helpful Docs

- Wiki home: `https://wiki.hypr.land/`
- Start page: `https://wiki.hypr.land/Configuring/Start/`
- Basics: `https://wiki.hypr.land/Configuring/Basics/`
- Variables: `https://wiki.hypr.land/Configuring/Basics/Variables/`
- Monitors: `https://wiki.hypr.land/Configuring/Basics/Monitors/`
- Binds: `https://wiki.hypr.land/Configuring/Basics/Binds/`
- Dispatchers: `https://wiki.hypr.land/Configuring/Basics/Dispatchers/`

## Known Quirks Here

- Home Manager's Hyprland plugin option generates `hyprland.conf` entries, so it is not the right place for this repo's Lua-native root config.
- If a value really needs to come from Nix, generate a small imported Lua file instead of rewriting the hand-written config style.
