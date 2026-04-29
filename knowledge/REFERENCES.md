# References

External documentation index for heavily used inputs, tools, and configured programs in this repo.

Related repo-specific guidance: [Foundations](FOUNDATIONS.md)

## How To Keep This Current

- Add or update entries when the repo starts depending on a non-trivial input, tool, or configured program.
- Prefer authoritative docs first. If a project does not have formal docs, link the upstream repository.
- Keep entries short: what it is, why it matters here, and the best URL to start from.
- Link related entries from [Encountered Problems](ENCOUNTERED-PROBLEMS.md) when a tool has a history of repeated mistakes.

## Flake Composition

- `flake-parts`: core module system and `perSystem` model used by this flake. Start here for the high-level model, then use the option reference for concrete module keys and merge behavior. `https://flake.parts/`
- `flake-parts` option reference: canonical option index for the schema this repo's flake modules implement, including `imports`, `perSystem`, `flake`, and nested option shapes. `https://flake.parts/options/flake-parts.html`
- `flake-parts` module arguments: canonical reference for `inputs'`, `self'`, `withSystem`, and `moduleWithSystem`, plus the rule that module functions only receive explicitly named arguments. `https://flake.parts/module-arguments.html`
- `flake-parts.modules` docs: reference for publishing typed modules under `flake.modules.<class>.*` and for using `withSystem` from those modules when they need per-system outputs. `https://flake.parts/options/flake-parts-modules.html`
- `flake-parts` reusable-module guide: reference for exporting `flake.flakeModules`, why they cannot be imported back through `self`, and when to use `importApply` to pass local flake scope into a reusable module. `https://flake.parts/dogfood-a-reusable-module.html`
- `flake-file`: generates the root `flake.nix` from repo declarations. `https://flake-file.oeiuwq.com/overview/`
- Dendritic pattern guide: the main reference for the modular flake structure used here, especially the basics, aspect patterns, and comprehensive example. `https://github.com/Doc-Steve/dendritic-design-with-flake-parts`
- Dendritic basics: the reference for feature naming, `flake.modules.<class>.<aspect>`, and `flake-parts.nix` boilerplate placement. `https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Basics#basics-for-usage-of-the-dendritic-pattern`
- Dendritic comprehensive example: the closest reference for how this repo organizes hosts and users as feature directories rather than central registries. `https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Comprehensive_Example#comprehensive-example`
- `import-tree`: helper used to import the `modules/` tree into `mkFlake`. `https://github.com/vic/import-tree`
- `import-tree` docs: reference for recursive import behavior, including the default convention that ignores paths containing `/_`. `https://import-tree.oeiuwq.com`

## Workflow Inputs

- `home-manager`: NixOS and standalone Home Manager modules used for user-level configuration in this repo. `https://nix-community.github.io/home-manager/`
- `Hyprland` wiki home: versioned entrypoint to the full docs; by default this tracks the latest git documentation and links outward to setup, configuring, ecosystem, and Wayland background pages. `https://wiki.hypr.land/`
- `Hyprland` wiki start page: canonical reference for the Lua config model, file location, and core API shape now used by this repo's Hyprland configuration. `https://wiki.hypr.land/Configuring/Start/`
- `Hyprland` basics index: first-stop overview for the core config areas you will usually expand next, including variables, monitors, binds, dispatchers, rules, and autostart. `https://wiki.hypr.land/Configuring/Basics/`
- `Hyprland` variables docs: reference for the top-level config sections and option families you will commonly tune before drilling into subsystem-specific pages. `https://wiki.hypr.land/Configuring/Basics/Variables/`
- `Hyprland` monitors docs: reference for output naming, mode strings, scale, transform, mirroring, and reserved areas when display layout changes. `https://wiki.hypr.land/Configuring/Basics/Monitors/`
- `Hyprland` bind and submap docs: reference for `hl.bind`, bind flags, keybind ordering, and `hl.define_submap` semantics used by the generated keybind setup. `https://wiki.hypr.land/Configuring/Basics/Binds/`
- `Hyprland` dispatcher docs: canonical dispatcher list plus selector syntax for workspaces, windows, and monitor-targeted actions. `https://wiki.hypr.land/Configuring/Basics/Dispatchers/`
- `Hyprland` window rules docs: reference for rule matching, per-window effects, and layer rules when behavior should depend on app or surface identity. `https://wiki.hypr.land/Configuring/Basics/Window-Rules/`
- `Hyprland` workspace rules docs: reference for per-workspace layout, gaps, border, and monitor assignment behavior. `https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/`
- `Hyprland` autostart docs: reference for startup hooks and session boot commands when more services or helpers should launch with the compositor. `https://wiki.hypr.land/Configuring/Basics/Autostart/`
- `Hyprland` configuring index: high-level map of the full configuration docs, including basics, layouts, advanced topics, and example configurations. `https://wiki.hypr.land/Configuring/`
- `Hyprland` scrolling layout docs: reference for the layout-specific options and behavior this repo currently uses. `https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/`
- `Hyprland` gestures docs: reference for gesture syntax and trackpad actions beyond the basic examples. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/`
- `Hyprland` devices docs: reference for per-device overrides when touchpad, mouse, or tablet behavior needs hardware-specific tuning. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/`
- `Hyprland` environment variables docs: reference for compositor and toolkit environment variables when session behavior depends on Wayland integration details. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/`
- `Hyprland` multi-GPU docs: reference for mixed-GPU rendering setups and the first place to check when NVIDIA or multi-adapter behavior becomes relevant. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/Multi-GPU/`
- `Hyprland` XWayland docs: reference for compatibility behavior with legacy X11 applications, including scaling and socket details. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/XWayland/`
- `Hyprland` `hyprctl` docs: reference for runtime inspection and control from scripts or the terminal when debugging session behavior. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/`
- `Hyprland` permissions docs: reference for screen capture, global shortcuts, plugin permissions, and other security-gated integrations when extending Hyprland. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/`
- `Hyprland` performance docs: reference for rendering and performance tradeoffs when diagnosing slowdowns or tuning heavier setups. `https://wiki.hypr.land/Configuring/Advanced-and-Cool/Performance/`
- `disko`: declarative disk layout module used for host storage definitions. Start at the docs index, then use the quickstart, reference guide, and examples when shaping a host layout. `https://github.com/nix-community/disko/blob/master/docs/INDEX.md`
- `disko` quickstart: simplest install flow and first configuration shape. `https://github.com/nix-community/disko/blob/master/docs/quickstart.md`
- `disko` reference: detailed option and CLI reference. `https://github.com/nix-community/disko/blob/master/docs/reference.md`
- `mcp-nixos`: upstream flake providing the packaged MCP server used by the wrapped `opencode` package. `https://github.com/utensils/mcp-nixos`
- `github-mcp-server`: GitHub's official MCP server; use its README for auth, toolsets, and local `stdio` configuration details. `https://github.com/github/github-mcp-server`
- `sops-nix`: declarative secret provisioning used here to install encrypted secrets such as SSH private keys onto the target system at activation time. `https://github.com/Mic92/sops-nix`
- `sops`: the editor and encryption CLI used to create and rotate the encrypted files consumed by `sops-nix`. `https://github.com/getsops/sops`
- `age`: modern file encryption tool used here as the `sops-nix` recipient format. `https://age-encryption.org/`
- `ssh-to-age`: helper for converting SSH keys into `age` recipients when this repo later needs machine or user SSH keys as `sops` recipients. `https://github.com/Mic92/ssh-to-age`
- `treefmt-nix`: formatting integration used by the repo formatter and pre-commit gate. `https://github.com/numtide/treefmt-nix`
- `git-hooks.nix`: pre-commit hook integration used to install and run the repo gate. `https://github.com/cachix/git-hooks.nix`
- `nix-wrapper-modules`: wrapper helpers used to expose the configured `opencode` package. `https://github.com/BirdeeHub/nix-wrapper-modules`

## Configured Programs

- OpenCode upstream: terminal coding agent used by the wrapped `opencode` package. `https://github.com/anomalyco/opencode`
- OpenCode config docs: config file locations, merge behavior, and the `instructions` setting used in this repo. `https://opencode.ai/docs/config/`
- OpenCode rules docs: `AGENTS.md` behavior, precedence, and external instruction loading. `https://opencode.ai/docs/rules/`
- OpenCode config schema: authoritative schema for the wrapped `opencode` settings. `https://opencode.ai/config.json`
