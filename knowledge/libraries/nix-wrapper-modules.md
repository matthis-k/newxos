---
title: nix-wrapper-modules
type: note
permalink: newxos/libraries/nix-wrapper-modules
---

# nix-wrapper-modules

`nix-wrapper-modules` builds wrapped end-user program packages with repo-owned configuration. It provides a Nix function per supported program that takes the upstream package and overlays config files, environment variables, and wrapper scripts.

## Observations

- [fact] Wrapper package definitions are owned by nearby feature modules and `modules/desktop/wrappers/`
- [technique] Put custom wrapper module definitions in `modules/desktop/wrappers/`; install via `withSystem` and `self'.packages`
- [decision] Keep hand-written config in `configs/` and generated fragments in nearby modules when that split is cleaner
- [fact] Native Neovim compatibility has repo-specific source files under `configs/nvim/`; inspect source for current lock and loader behavior

## Relations

- relates_to [[Wrapped Programs And Generated Config]]
- relates_to [[Flake Structure]]

## What It Does Here

- Wrapper package definitions live near the feature that owns them.
- Custom desktop wrapper definitions live in `modules/desktop/wrappers/`.
- Neovim wrapper details and native compatibility files live under `modules/dev/` and `configs/nvim/`.
- Lets the repo install a configured program instead of only a raw upstream package.
- Keeps custom wrapper definitions in `modules/desktop/wrappers/` and hand-written app config in `configs/`.

## Basics

- Use a wrapper when the repo should ship the program with opinionated config.
- Put custom wrapper module definitions in `modules/desktop/wrappers/`.
- Install wrapped packages from reusable Home Manager or NixOS modules via `withSystem` and `self'.packages`.
- Keep hand-written config in `configs/` and generated fragments in nearby modules when that split is cleaner.
- Related reading: [[Wrapped Programs And Generated Config]], [[Flake Structure]].

## Upstream Overview

### Architecture

- Each supported program has a wrapper function under `inputs.nix-wrapper-modules.wrappers.<program>.wrap`.
- The wrapper takes a set of arguments and returns a wrapped derivation.
- Wrappers handle: config file generation, environment variable injection, wrapper script creation, dependency bundling.

### Wrapper inputs and supported programs

Check upstream source or the pinned flake input for the current wrapper argument schema and supported programs. Do not copy that list into memory; it changes with the library.

### Wrapper behavior

- Wrappers create a new derivation that wraps the original binary.
- Config files are written to the Nix store and referenced by the wrapper.
- The wrapper script sets up the environment (XDG paths, env vars) before exec'ing the real binary.
- Some wrappers support a "portable" mode where config lives alongside the binary rather than in XDG paths.

### Config generation strategy

- Wrapper-owned generated config should usually be imported into hand-written config, not copied and duplicated by hand.
- Reference `configs/` files via `builtins.readFile` when the hand-written config is the source of truth.

### Helpful Docs

- Upstream repo: `https://github.com/BirdeeHub/nix-wrapper-modules`
- This repo's wrapper configs: `modules/desktop/wrappers/`, `modules/dev/`, and `configs/`
- Related pattern: [[Wrapped Programs And Generated Config]]

## Known Quirks

- Prefer the wrapper if this repo already exposes one for the program.
- Wrapper-owned generated config should usually be imported into hand-written config, not copied and duplicated by hand.
- The Neovim wrapper's portable mode requires the lock file to stay in sync with the Nix plugin declarations.
- Some wrappers may not support all configuration options; check the wrapper source for supported arguments.
