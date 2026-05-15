---
title: nix-wrapper-modules
type: note
permalink: newxos/libraries/nix-wrapper-modules
---

# nix-wrapper-modules

`nix-wrapper-modules` builds wrapped end-user program packages with repo-owned configuration. It provides a Nix function per supported program that takes the upstream package and overlays config files, environment variables, and wrapper scripts.

## Observations

- [fact] Wraps `opencode`, `kitty`, Neovim, and custom QuickShell launchers as packages exposed by this flake
- [technique] Put custom wrapper module definitions in `modules/wrappers/`; install via `withSystem` and `self'.packages`
- [decision] Keep hand-written config in `configs/` and generated fragments in nearby modules when that split is cleaner
- [fact] Native Neovim compatibility uses static loader at `configs/nvim/lua/newxos/non_nix_compatibility.lua` plus generated `configs/nvim/nvim-pack-lock.json`

## Relations

- relates_to [[Wrapped Programs And Generated Config]]
- relates_to [[Flake Structure]]

## What It Does Here

- Wraps `opencode`, `kitty`, Neovim, and custom QuickShell launchers as packages exposed by this flake.
- The Neovim wrapper currently exposes a portable `nvim` package plus a repo-bound `nvimdev` variant for live editing against `configs/nvim`.
- Native Neovim compatibility uses the static loader at `configs/nvim/lua/newxos/non_nix_compatibility.lua` plus the generated `configs/nvim/nvim-pack-lock.json` written from the Nix plugin source of truth.
- Lets the repo install a configured program instead of only a raw upstream package.
- Keeps custom wrapper definitions in `modules/wrappers/` and hand-written app config in `configs/`.

## Basics

- Use a wrapper when the repo should ship the program with opinionated config.
- Put custom wrapper module definitions in `modules/wrappers/`.
- Install wrapped packages from reusable Home Manager or NixOS modules via `withSystem` and `self'.packages`.
- Keep hand-written config in `configs/` and generated fragments in nearby modules when that split is cleaner.
- Related reading: [[Wrapped Programs And Generated Config]], [[Flake Structure]].

## Upstream Overview

### Architecture

- Each supported program has a wrapper function under `inputs.nix-wrapper-modules.wrappers.<program>.wrap`.
- The wrapper takes a set of arguments and returns a wrapped derivation.
- Wrappers handle: config file generation, environment variable injection, wrapper script creation, dependency bundling.

### Common wrapper arguments

- **pkgs** — the nixpkgs package set (required).
- **extraConfig** — raw config text to inject into the generated config file.
- **extraConfigFiles** — attrset of relative path → content for additional config files.
- **extraPackages** — list of packages to add to the wrapper's PATH.
- **env** — attrset of environment variables to set in the wrapper.
- **preStart** — shell snippet to run before the program starts.
- **postStart** — shell snippet to run after the program starts.
- **wrapperArgs** — additional arguments passed to the wrapper script.
- **passthru** — attrset to merge into the derivation's passthru.

### Supported programs (non-exhaustive)

The library covers many popular tools. Commonly used ones include:

- **kitty** — terminal emulator; wraps with `kitty.conf`, additional config includes, font/theme files.
- **neovim** — editor; wraps with `init.lua`, plugin packs, runtime paths, environment setup.
- **helix** — editor; wraps with `config.toml`, `languages.toml`, theme files.
- **alacritty** — terminal emulator; wraps with `alacritty.toml`/`alacritty.yml`.
- **foot** — terminal emulator; wraps with `foot.ini`.
- **zellij** — terminal multiplexer; wraps with `config.kdl`, layout files.
- **tmux** — terminal multiplexer; wraps with `tmux.conf`.
- **ghostty** — terminal emulator; wraps with config files.
- **mpv** — media player; wraps with `mpv.conf`, `input.conf`, script files.
- **firefox** / **zen** — browsers; wraps with policies, preferences, profile setup.
- **thunderbird** — email client; wraps with policies and preferences.

Check `inputs.nix-wrapper-modules.wrappers` for the full current list.

### Wrapper behavior

- Wrappers create a new derivation that wraps the original binary.
- Config files are written to the Nix store and referenced by the wrapper.
- The wrapper script sets up the environment (XDG paths, env vars) before exec'ing the real binary.
- Some wrappers support a "portable" mode where config lives alongside the binary rather than in XDG paths.

### Integration pattern

```nix
# Basic wrapper usage
packages.kitty = inputs.nix-wrapper-modules.wrappers.kitty.wrap {
  inherit pkgs;
  extraConfig = ''
    include ~/.config/kitty/stylix-theme.auto.conf
    ${builtins.readFile ../../configs/kitty/kitty.conf}
  '';
};

# With extra packages and environment
packages.neovim = inputs.nix-wrapper-modules.wrappers.neovim.wrap {
  inherit pkgs;
  extraPackages = [ pkgs.ripgrep pkgs.fzf ];
  env.LANG = "en_US.UTF-8";
  extraConfigFiles."init.lua".text = builtins.readFile ../../configs/nvim/init.lua;
};
```

### Config generation strategy

- Wrapper-owned generated config should usually be imported into hand-written config, not copied and duplicated by hand.
- Use `extraConfig` for small inline snippets.
- Use `extraConfigFiles` for larger or structured config that benefits from being a separate file.
- Reference `configs/` files via `builtins.readFile` when the hand-written config is the source of truth.

### Helpful Docs

- Upstream repo: `https://github.com/BirdeeHub/nix-wrapper-modules`
- This repo's wrapper configs: `configs/` directory
- Related pattern: [[Wrapped Programs And Generated Config]]

## Known Quirks

- Prefer the wrapper if this repo already exposes one for the program.
- Wrapper-owned generated config should usually be imported into hand-written config, not copied and duplicated by hand.
- The Neovim wrapper's portable mode requires the lock file to stay in sync with the Nix plugin declarations.
- Some wrappers may not support all configuration options; check the wrapper source for supported arguments.
