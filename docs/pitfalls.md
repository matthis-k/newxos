# Pitfalls

Project-specific gotchas and recurring mistakes.

## Nix scope mistakes

### `modulesPath` missing from outer flake-parts module args

Problem: requesting `modulesPath` from the outer flake-parts file function for a `flake.modules.nixos.*` declaration.

Fix: define `flake.modules.nixos.<name>` as a NixOS module function when it needs NixOS-only args.

### Reaching for `self.packages.${system}` instead of `withSystem` and `self'`

Fix: use `withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: ...)` inside reusable modules.

### Defaulted outer module args still require `_module.args` when reused as NixOS modules

Fix: do not parameterize exported `flake.modules.nixos.*` modules with ad hoc outer args.

### `imports` inside `lib.mkMerge`

Putting `imports` inside `mkMerge` makes it part of module `config`, causing `The option 'imports' does not exist`.

Fix: keep `imports` at the module top level, put conditional options under `config = lib.mkMerge [...]`.

## Quickshell

### Module version mismatch

Importing a newer QuickShell module (e.g. `Quickshell.Networking`) while the pinned nixpkgs still has an older `quickshell` binary causes `module "..." is not installed`.

Fix: update nixpkgs lock to a revision that ships the required QuickShell version.

### Environment variables in QML

`Qt.application.environment` can silently read as unset in Quickshell.

Fix: use `Quickshell.env("VAR")` for live Quickshell environment checks.

### Launcher retained whole tree per keystroke

Candidate retention must require indexed candidate family, direct evidence, or retained children. Permission alone is not proof of relevance.

### Launcher result rows carried circular evaluated trees

Keep only primitive row fields, actions, and evidence metadata in normalized rows.

### Launcher prewarm cached empty desktop apps

Do not prewarm backends whose source model is populated asynchronously.

### Animated list reveals looked vertically centered

Animate only the clipped wrapper height and keep the content item/layout at its real target height, top-anchored. Source: `configs/newshell/components/Expander.qml`.

For `ListView` removals, use `ListView.delayRemove` and collapse delegate height before removal. Prefer `AnimatedListDelegate.qml` for list rows.

### QML subdirectory singleton imports not resolved in JS

Only same-directory imports or directory imports register the type name. Keep `pragma Singleton` files in the same directory as their consumers, or use `import "subdir/"` instead of file imports.

## Build and shell

### Pre-commit hook breaks after Nix GC

Hook references an absolute store path that GC removes.

Fix: run `nix run "path:$PWD#install-git-hooks"` after GC.

### Stale generated `flake.nix` misleads `nix flake show` / `nix flake check`

After changing `flake-file` declarations, `show` and `check` may reflect old output.

Fix: run `nix run "path:$PWD#write-flake"` before running flake introspection commands.

### Lua multi-return collapses in table constructors

`unpack(...)` in a non-final table field contributes only the first return value.

Fix: build the list first, then extend with extra values instead of unpacking mid-table.

### `PanelWindow` may not resolve in `qmlls`

`PanelWindow` is provided by Quickshell's runtime, not by a static QML module.

Fix: ignore the `qmlls` unresolved-type warning for `PanelWindow`. Leave `.qmlls.ini` untracked; Quickshell manages it per machine.

### Store-backed wrapper config requires rebuild

Config changes managed by a nix-wrapper-modules wrapper take effect only after a NixOS or Home Manager rebuild.

Fix: use the source-tree wrapper (dev specialization) when iterating on `configs/newshell/` without rebuilding.

## Theming

### Generic Base16 targets lose semantic contrast

Flattening a full palette into Base16 slots before browser-specific UI groups lose contrast intent.

Fix: generate repo-owned CSS from `config.stylix.fullPalette.colors` when more nuance is needed.

### Zen Browser chrome not themed

Stylix does not generate `userChrome.css` for Zen by default.

Fix: generate repo-owned Zen CSS from the full palette. Source: `modules/theming/`.

### `stylix.homeManagerIntegration.autoImport` must stay off

Enabling auto-import creates a second implicit Home Manager entrypoint.

Fix: keep `autoImport = false` so the repo's explicit HM module remains the single source of truth.

### Built-in Kitty and Fish Stylix targets disabled

Stylix's built-in Kitty/Fish targets produce simpler output than this repo's Catppuccin-shaped generated themes.

Fix: repo-owned Kitty and Fish themes come from `modules/theming/`. Do not re-enable the built-in targets.

### Built-in Zen Browser Stylix target disabled

The generic Base16 target flattens the full palette before browser groups, losing contrast intent for selected tabs and urlbar suggestions.

Fix: repo-owned Zen CSS is generated from `config.stylix.fullPalette.colors` in `modules/theming/`.

### Cursor theme from upstream flake, not raw files

Cursor theme is sourced from a packaged upstream cursor flake's blue output.

Fix: do not copy raw theme files into the repo. Reference the upstream flake output instead.

### GTK and Qt stay on Stylix-managed theming

GTK and Qt use Stylix defaults. The repo only overrides app theming when Stylix's target is insufficient.

Fix: start app-specific theme overrides in `modules/theming/`, not in individual app configs.

### Repo font defaults in Stylix module, not host boot modules

Font choices affect GRUB, console, and display manager — not only the desktop session.

Fix: set font defaults in `modules/theming/stylix.nix`. Host boot modules should not duplicate them.

### Start custom theme tweaks in `modules/theming/`

A tweak that should apply across multiple apps needs a shared source.

Fix: add cross-app theme changes to `modules/theming/`, then reference from individual app configs.

## Hyprland

### Home Manager plugin generates `hyprland.conf`, not suitable for Lua config

HM's Hyprland plugin option generates legacy `hyprland.conf` entries, which do not compose with this repo's Lua-native `configs/hypr/hyprland.lua`.

Fix: keep HM Hyprland options minimal or disabled. Use the wrapper-generated `nix-import.lua` for Nix-derived values.

### `.luarc.json` stubs path varies by installation

Hyprland 0.55+ uses Lua config. LSP needs stubs at a path that depends on how Hyprland is installed.

Fix: keep `.luarc.json` at repo root pointed at the correct Hyprland stubs path. The path changes between Nix-managed and system-managed Hyprland.

### Native Lua binds are registered events, not raw input

Hyprland Lua `hl.bind` can observe registered press/release binds and timers, but it is not a raw all-key down/up stream. Do not set `unknown_chord_policy = "any_key"` or claim unknown keys suppress held-key taps unless a raw input backend exists.

Fix: keep the Hyprland backend on `registered_only`; add explicit registered chords or extend the backend boundary rather than adding Super/Caps-specific tap suppression.

### Standalone modifier sentinels use target modmask plus physical key

Hyprland's Lua bind docs specify modifier-only binds as the target modmask plus the physical modifier key, with `release = true` for release behavior: `hl.bind("ALT + ALT_L", ..., { release = true })`. For Super, use `SUPER + SUPER_L` and `SUPER + SUPER_R` sentinels.

Fix: do not bind modifier-only sentinels as bare `SUPER_L`/`ALT_L` unless upstream docs change. The resolver backend should register press/release sentinels using the documented target-modmask form and dispatch resolved actions through `hl.dispatch`.

## Wrappers

### Prefer existing wrapper over raw package

When the repo has a `nix-wrapper-modules` wrapper for a program, use it instead of wiring the raw upstream package.

Fix: install wrapped packages via `withSystem` and `self'.packages` from reusable modules. Check `modules/desktop/wrappers/` for existing wrapper definitions.

### Wrapper-generated config should be imported, not duplicated

Wrapper-owned generated Nix config files should be imported into hand-written config, not copied by hand.

Fix: reference generated config via `builtins.readFile` or wrapper-provided paths. Do not duplicate Nix-generated values in hand-written configs.

### Neovim wrapper portable mode lock must stay in sync

The Neovim wrapper's portable mode uses a lock file that must reflect the Nix plugin declarations.

Fix: after changing Nix Neovim plugin lists, regenerate the lock file. Source: `modules/dev/neovim.nix`.

## Secrets and containers


