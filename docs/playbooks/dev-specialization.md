# Dev specialization

A NixOS specialization that switches programs to use live configs from the repo instead of Nix-built copies. Controlled by `newxos.devMode` option and `NEWXOS_DEV` environment variable.

## How it works

The specialization sets `newxos.devMode = true`. Programs that support live configs check this flag:

- **QuickShell**: wrapper switches from Nix-built config to `${NEWXOS_FLAKE:-$HOME/newxos}/configs/newshell` when `NEWXOS_DEV=1`.
- **Neovim**: wrapper dispatches to live repo config wrapper when `NEWXOS_DEV=1`.
- **Hyprland**: wrapper creates merged config directory that symlinks live configs and copies Nix-generated `nix-import.lua`.

## Adding to a host

```nix
imports = with inputs.self.modules.nixos; [
  devSpecialization
];
```

## Switching at runtime

```bash
sudo /run/current-system/specialisation/dev/bin/switch-to-configuration test
```

## Key files

- `modules/dev/dev-specialization.nix` — specialization definition
- `modules/desktop/wrappers/quickshell.nix` — newshell runtime config selector
- `modules/desktop/wrappers/hyprland.nix` — wrapper with live config merging
- `modules/dev/neovim.nix` — nvim runtime config selector
- `configs/newshell/utils/DevLogger.qml` — conditional logging helper
