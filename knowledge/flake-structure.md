# Flake Structure

Keep the root flake thin. Most behavior lives under `modules/` and `configs/`.

## Top Level

- `flake.nix`: generated file. Do not hand edit.
- `flake.lock`: pinned inputs.
- `modules/`: source of truth for flake behavior, reusable modules, inputs, packages, and concrete outputs.
- `configs/`: hand-written program config copied or wrapped into system or Home Manager config.
- `secrets/`: encrypted secret payloads only.
- `knowledge/`: repo memory for workflow, libraries, patterns, structure, and issues.
- `AGENTS.md`: short agent entrypoint that points at the knowledge pages.
- `opencode.json`: tells OpenCode which knowledge pages to load automatically.
- `.sops.yaml`: secret recipient and encryption rules.

## `modules/`

- Keep shared repo behavior near the top level of `modules/`.
- Use small focused files like `nix.nix`, `networking.nix`, `workflow.nix`, `home-manager.nix`, `sops.nix`, and `disko.nix` for shared wiring.
- Use feature directories when one concern needs multiple files.
- Current feature directories include `stylix/`, `desktops/`, `editors/`, `shells/`, `terminals/`, `browsers/`, `development/`, `vpns/`, `hosts/`, and `users/`.
- Related reading: [Dendritic Feature Modules](patterns/dendritic-modules.md).

## `modules/hosts/`

- One directory per concrete NixOS system.
- Keep host-local boot, hardware, storage, swap, and user-linking files close to the host.
- Good examples are files like `configuration.nix`, `boot.nix`, `filesystem.nix`, `swap.nix`, and `hardware-configuration.nix`.
- If `disko` manages storage, keep it as the source of truth and avoid duplicated `fileSystems` declarations.
- Installer hosts follow the same pattern.
- Related reading: [Host And User Layout](patterns/host-and-user-layout.md), [disko](libraries/disko.md).

## `modules/users/`

- One directory per real user.
- Keep user-specific Home Manager and closely related NixOS user wiring here.
- Prefer co-locating small NixOS and Home Manager declarations when they describe the same user.
- Related reading: [Host And User Layout](patterns/host-and-user-layout.md), [home-manager](libraries/home-manager.md).

## `modules/stylix/`

- Keep repo-owned palette logic and generated theme integration here.
- Prefer putting custom theme logic into the Stylix module instead of scattering color decisions through program configs.
- Generated theme fragments should usually be imported from program configs instead of being hand-written inside `configs/`.
- Current examples are generated `kitty/stylix-theme.auto.conf` and `fish/stylix-theme.auto.fish`.
- Related reading: [stylix](libraries/stylix.md), [Wrapped Programs And Generated Config](patterns/wrapped-programs.md).

## `configs/`

- Keep hand-written app config here when it should stay editable outside pure Nix logic.
- Use this for files like `configs/hypr/hyprland.lua`, `configs/hypr/keybinds.lua`, `configs/kitty/kitty.conf`, `configs/nvim/init.lua`, and `configs/quickshell/shell.qml`.
- Prefer importing generated pieces from Nix when some part should stay derived from repo state.
- Keep generated files out of git when they can be created by modules.
- Related reading: [hyprland](libraries/hyprland.md), [Wrapped Programs And Generated Config](patterns/wrapped-programs.md).

## `secrets/`

- Only store encrypted secret payloads here.
- Keep public companions like `*.pub` as normal tracked files when useful.
- Do not store plaintext secrets here.
- Do not inspect secret values unless the user explicitly asks.
- Related reading: [sops-nix](libraries/sops-nix.md), [Workflow](workflow.md#secrets-and-data-care).

## `knowledge/`

- `README.md`: quick map of the knowledgebase.
- `workflow.md`: how to work in this repo.
- `flake-structure.md`: this file.
- `libraries/`: upstream tools and their repo-specific usage notes.
- `patterns/`: common repo composition patterns.
- `encountered_issues.md`: append-only gotchas and mistakes.

## Placement Rules

- Put shared infrastructure in shared modules unless it is truly host-local.
- Put concrete outputs close to the feature they expose.
- Put repo-owned program wrapping in modules, and hand-written program config in `configs/`.
- Put custom themes and theme generation in `modules/stylix/`, then import the generated files where feasible.
- Put starter guidance in `knowledge/` pages like [Dendritic Feature Modules](patterns/dendritic-modules.md) and [Workflow Tooling](libraries/workflow-tooling.md) instead of shipping example template flakes.
- Put reusable docs in `knowledge/`, not in `AGENTS.md`.
