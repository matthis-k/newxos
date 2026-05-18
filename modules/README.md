# Modules

`import-tree` recursively imports every `.nix` file below this directory. Folder names are organizational; exported `flake.modules.*` names are the stable API.

## Categories

- `common/`: shared NixOS modules and cross-host bundles.
- `core/`: flake-file/import-tree bootstrap and shared flake inputs.
- `desktop/`: desktop environment, shell, terminal, and wrapper modules.
- `dev/`: developer tooling, editors, Git, OpenCode, workflow checks, and development packages.
- `gaming/`: reserved for game platform, Proton/Wine, controller, and low-latency modules.
- `installation/`: installer media and install-only support modules.
- `network/`: network services and VPN integrations.
- `socials/`: browser and communication-oriented user applications.
- `theming/`: Stylix and repo-owned generated theme targets.
- `hosts/`: concrete NixOS machines.
- `users/`: real user profiles and shared user wiring.
