# hyprland

Hyprland provides the graphical desktop session used by this repo.

## What It Does Here

- The upstream flake input provides the compositor packages.
- The NixOS module enables the session and supporting packages.
- Home Manager copies the hand-written `configs/hypr/` tree into `~/.config/hypr`.
- Nix-generated values should go into `~/.config/hypr/nix-import.lua` instead of cluttering the hand-written root config.

## Basics

- Keep `configs/hypr/hyprland.lua` as the hand-written root config.
- Keep structured binds in `configs/hypr/keybinds.lua`.
- Prefer editing the Lua config tree instead of generating the whole Hyprland config from Nix.
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
