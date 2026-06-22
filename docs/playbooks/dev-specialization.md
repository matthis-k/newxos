# Dev specialization

A NixOS specialization that switches programs to use live configs from the repo instead of Nix-built copies. Controlled by `newxos.devMode` option and `NEWXOS_DEV` environment variable.

## How it works

The specialization sets `newxos.devMode = true`. Programs that support live configs check this flag.

Source: `modules/dev/dev-specialization.nix` owns exact program support; `modules/desktop/wrappers/` owns wrapper behavior.

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
