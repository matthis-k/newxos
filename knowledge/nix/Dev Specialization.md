---
title: Dev Specialization
type: note
permalink: newxos/knowledge/nix/dev-specialization
---

# Dev Specialization

NixOS specialization that switches desktop programs to use live configs from the repo instead of Nix-built copies.

## Observations

- [fact] Specialization lives in `modules/dev/dev-specialization.nix` and exports `newxos.devMode` option
- [technique] Wrappers read `NEWXOS_DEV=1` at runtime to choose live repo configs; the dev specialization exports this environment variable from `newxos.devMode`
- [decision] Single `dev` specialization shared across all hosts; each host imports `devSpecialization` module
- [fact] QuickShell logging via `DevLogger.qml` only outputs when `NEWXOS_DEV=1` environment is set
- [fact] Hyprland merges Nix-generated `nix-import.lua` into live config directory at runtime

## Relations

- part_of [[Flake Structure]]
- relates_to [[QuickShell]]
- relates_to [[Hyprland]]
- relates_to [[Wrapped Programs And Generated Config]]

## How It Works

The specialization sets `newxos.devMode = true` in its configuration. Programs that support live configs check this flag:

### QuickShell
- Module: `modules/desktop/quickshell.nix`
- Wrapper: `modules/desktop/wrappers/quickshell.nix`
- Installs one `newshell` wrapper that uses Nix-built config by default and switches to `${NEWXOS_FLAKE:-$HOME/newxos}/configs/quickshell` when `NEWXOS_DEV=1`
- Systemd service sets `NEWXOS_DEV=1` in dev mode
- `DevLogger.qml` checks `Qt.application.environment["NEWXOS_DEV"] === "1"` before logging

### Neovim
- Module: `modules/dev/neovim.nix`
- Installs one `nvim` wrapper that uses Nix-built config by default and dispatches to the live repo config wrapper when `NEWXOS_DEV=1`

### Hyprland
- Module: `modules/desktop/hyprland.nix`
- Wrapper: `modules/desktop/wrappers/hyprland.nix`
- When `devMode = true`, wrapper uses `escapeShellArgWithEnv` for runtime path expansion
- Creates merged config directory that symlinks live configs and copies Nix-generated `nix-import.lua`
- Per-host monitor definitions still apply through `luaVariables`

## Usage

Add to any host configuration:

```nix
imports = with inputs.self.modules.nixos; [
  devSpecialization
];
```

Switch to dev specialization at runtime:

```bash
sudo /run/current-system/specialisation/dev/bin/switch-to-configuration test
```

## Files

- `modules/dev/dev-specialization.nix`: specialization definition and `NEWXOS_DEV` runtime environment export
- `configs/quickshell/utils/DevLogger.qml`: conditional logging helper
- `modules/desktop/quickshell.nix`: quickshell package and service wiring
- `modules/desktop/wrappers/quickshell.nix`: `newshell` runtime config selector
- `modules/desktop/hyprland.nix`: hyprland wrapper with devMode support
- `modules/desktop/wrappers/hyprland.nix`: wrapper with live config merging
- `modules/dev/neovim.nix`: `nvim` runtime config selector
