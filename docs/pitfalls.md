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

### Networking crash (resolved)

Quickshell 0.3.0 segfaults during Wi-Fi scan due to `NMAccessPoint` use-after-free.

Fix: use `nmcli` via `Process` instead of `Quickshell.Networking`. Source: `configs/quickshell/services/NetworkService.qml`.

### Module version mismatch

Importing a newer QuickShell module (e.g. `Quickshell.Networking`) while the pinned nixpkgs still has an older `quickshell` binary causes `module "..." is not installed`.

Fix: update nixpkgs lock to a revision that ships the required QuickShell version.

### Launcher retained whole tree per keystroke

Composite search treated every allowed node as a candidate even without evidence, causing high CPU.

Fix: candidate retention must require indexed candidate family, direct evidence, or retained children. Permission alone is not proof of relevance.

### Launcher result rows carried circular evaluated trees

`toResultRow` returned `raw: ev` where evaluated nodes contain parent/tree references.

Fix: keep only primitive row fields, actions, and evidence metadata in normalized rows.

### Launcher prewarm cached empty desktop apps

Prewarming `DesktopAppsBackend` before `DesktopEntries` populated cached an empty tree.

Fix: do not prewarm backends whose source model is populated asynchronously.

### Launcher action groups looked blank with nested children

Category groups defaulted to nested display, showing non-executable parent rows.

Fix: make `ActionGroupNode` default to flattening category matches into actionable descendant rows.

### Environment variables in QML

`Qt.application.environment` can silently read as unset in Quickshell.

Fix: use `Quickshell.env("VAR")` for live Quickshell environment checks.

### Launcher results frame collapsed with valid results

Frame height depended only on `resultsColumn.implicitHeight`, which can be 0 briefly during Loader initialization.

Fix: reserve a minimum height from model count whenever results exist.

### Animated list reveals looked vertically centered

Resizing the list/content item itself during shrink/grow makes QML preserve internal position, so a short result set can appear vertically centered after filtering. Letting a layout fill an animated parent height has the same effect: the layout can redistribute children during the intermediate shrink frames.

Fix: animate only the clipped wrapper height and keep the content item/layout at its real target height, top-anchored. Source: `configs/quickshell/components/Expander.qml`, `configs/quickshell/components/ListReveal.qml`.

For `ListView` removals, set `ListView.delayRemove` on the delegate wrapper and clear it after the clipped wrapper height animates to zero. Prefer `configs/quickshell/components/AnimatedListDelegate.qml` for list rows so normal height changes and removals share the same top-clipped behavior.

If a launcher row replays its add/expand animation on every keystroke, the view is probably receiving snapshot-array resets for the same logical row. Fix: pass stable row ids into `AnimatedListDelegate.animationKey` with a shared `seenKeys` object so only genuinely new ids run add animation.

### QML subdirectory singleton imports not resolved in JS

`import "subdir/Singleton.qml"` from a parent-file does not make `Singleton` available as a JS identifier. Only same-directory imports (`import "Singleton.qml"`) or directory imports (`import "subdir/"`) register the type name.

Fix: keep `pragma Singleton` QML files in the same directory as their consumers, or use directory imports (`import "subdir/"`) instead of file imports. A directory import loads all `.qml` files in that directory.

## Build and shell

### `buildEnv` tool bundles cannot mix wrapped compiler toolchains

Mixing `gcc` and `clang` wrappers in one `pkgs.buildEnv` bundle causes `conflicting subpath` for `bin/ld`.

Fix: keep one compiler toolchain per `buildEnv`, add only tools that do not collide.

### Multiline shell snippets in pipelines

Interpolating multiline shell fragments before a `|` in generated scripts produces `syntax error near unexpected token '|'`.

Fix: keep full pipeline in one script body, or use `case` dispatch.

### Shell arity guards blocking env fallback

Requiring too many positional args before reaching env-backed defaults makes the default branch unreachable.

Fix: align argument-count guards with truly required args only.

### Pre-commit hook breaks after Nix GC

Hook references an absolute store path that GC removes.

Fix: run `nix run "path:$PWD#install-git-hooks"` after GC.

### Pre-commit hook can rewrite files

Hook may reformat or modify files, changing staged content.

Fix: re-stage task-related files after hooks run. Do not assume the hook only validates.

### Stale generated `flake.nix` misleads `nix flake show` / `nix flake check`

After changing `flake-file` declarations, `show` and `check` may reflect old output.

Fix: run `nix run "path:$PWD#write-flake"` before running flake introspection commands.

### `repo-gate` reuses hook graph without staging

`repo-gate` runs the full pre-commit hook graph over the whole worktree without requiring staged files.

Fix: use `repo-gate` as the handoff check — it catches issues `git commit` would catch without needing `git add` first.

### Lua multi-return collapses in table constructors

`unpack(...)` in a non-final table field contributes only the first return value.

Fix: build the list first, then extend with extra values instead of unpacking mid-table.

### `PanelWindow` may not resolve in `qmlls`

`PanelWindow` is provided by Quickshell's runtime, not by a static QML module.

Fix: ignore the `qmlls` unresolved-type warning for `PanelWindow`. Leave `.qmlls.ini` untracked; Quickshell manages it per machine.

### Store-backed wrapper config requires rebuild

Config changes managed by a nix-wrapper-modules wrapper take effect only after a NixOS or Home Manager rebuild.

Fix: use the source-tree wrapper (dev specialization) when iterating on `configs/quickshell/` without rebuilding.

### Breaking changes expected before Quickshell 1.0

Quickshell pre-1.0 may change APIs between versions.

Fix: use upstream migration guides, not stale notes. Update nixpkgs lock when a newer module is needed.

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

### Open WebUI TTS split setting persisted over Nix env

Persistent SQLite config overrode declarative `AUDIO_TTS_SPLIT_ON`.

Fix: disable persistent config or use valid splitter values (`punctuation`, `paragraphs`, `none`).

### Kokoro GPU container image and CDI selector

Docker `--gpus all` can select a missing AMD CDI spec on mixed-GPU hosts.

Fix: use explicit `--device nvidia.com/gpu=all` and verify image tags with a container probe.

### Zen cannot import Caddy CA from private state path

`/var/lib/caddy/.../root.crt` is not user-readable.

Fix: publish to a world-readable path like `/run/caddy-local-root.crt`.

## ATA DRM logs are not graphics DRM

Kernel `ata*.00 supports DRM functions` refers to drive feature support, not Direct Rendering Manager.

Fix: for Plymouth/NVIDIA issues, focus on `simpledrm`, `nvidia_drm`, and framebuffer handoff.

## Token dedup: best-per-token by default

Evidence dedup changed from `(tokenIndex, fieldGroup)` to `(tokenIndex)` — only the highest-scoring evidence per token is kept by default.

If a node needs the old per-field-group dedup, set `profile.tokenDedup = "field-group"` in its `evaluationProfile.profile`.

Default behavior is `"best-per-token"` (set in `Evaluate.qml:85`). The dedup function lives in `Evidence.qml:bestPerToken()`.

### `buildChildTree` fallback bypassed shaping decision

The shaping step (`ResultShaping.qml`) explicitly sets `childEvs: []` when it decides children should not be visible (e.g., when `childPassesVisible` returns false for `expand-on-trailing-space` policy). However, `buildRowsFromShaped` in `Engine.qml:88-92` treated empty `childEvs` the same as null, falling through to `buildChildTree` which re-added children based on a simpler filter (`visible || score >= 0.25`), bypassing the shaping decision entirely.

Fix: check `item.childEvs != null` instead of `item.childEvs != null && item.childEvs.length > 0`. When `childEvs` is explicitly empty, respect the shaping decision and produce no child rows. Source: `Engine.qml:88-92`.
