---
title: flake-parts
type: note
permalink: newxos/libraries/flake-parts
---

# flake-parts

`flake-parts` is the core module system for this flake. It provides a composable, option-driven way to define flake outputs using the Nix module system.

## Observations

- [fact] Defines the top-level schema for `imports`, `perSystem`, and `flake`
- [technique] Use `inputs'` and `self'` inside `perSystem`; use `withSystem` to re-enter per-system scope from top-level reusable modules
- [decision] Lets the repo export reusable modules under `flake.modules.*`
- [fact] Most hard Nix mistakes in this repo are scope mistakes

## Relations

- relates_to [[Scope Boundaries And Per-System Access]]
- relates_to [[Dendritic Feature Modules]]

## What It Does Here

- Defines the top-level schema for `imports`, `perSystem`, and `flake`.
- Lets the repo export reusable modules under `flake.modules.*`.
- Gives the repo `withSystem`, `inputs'`, and `self'` for clean per-system access.
- Works together with the dendritic layout so most behavior lives in small modules under `modules/`.

## Basics

- Use plain `inputs` for global flake wiring.
- Use `perSystem` for system-specific packages, apps, checks, and dev shells.
- Use `inputs'` and `self'` inside `perSystem` instead of manually indexing `.${system}` when a proper per-system view exists.
- Use `withSystem` when a top-level reusable module needs a per-system package.
- Related reading: [[Scope Boundaries And Per-System Access]], [[Dendritic Feature Modules]].

## Upstream Overview

### Architecture

- `flake-parts` wraps the Nix module system for flakes.
- A flake imports `flake-parts.lib.mkFlake { inherit inputs; } modules` as its output function.
- Each module is a function `{ inputs, ... }: { ... }` that returns a flake-parts configuration.
- Modules compose via `imports`, merging options and outputs.

### Module arguments (top-level)

- `inputs` — all flake inputs, merged from the flake's `inputs` attrset.
- `self` — the flake's own outputs (partially constructed).
- `system` — available inside `perSystem` context only.

### Key configuration keys

**imports** — list of modules to include. Can be flake modules (e.g., `inputs.treefmt-nix.flakeModule`), inline attrsets, or file paths.

**systems** — list of system strings (e.g., `[ "x86_64-linux" "aarch64-linux" ]`). Usually set from `inputs.nixpkgs.systems` or hardcoded.

**perSystem** — function `{ self', inputs', pkgs, system, ... }: { ... }` evaluated once per system. Returns system-scoped outputs.

**flake** — function `{ self', inputs', ... }: { ... }` for non-system-specific flake outputs. Returns the raw flake output attrset.

**debug** — boolean to enable debug output.

### perSystem outputs

Inside `perSystem`, the following output keys are recognized:

- **packages** — derivations built by the flake. Accessed as `nix build .#<name>`.
- **apps** — runnable applications with `nix run .#<name>`. Each is `{ type = "app"; program = "<path>"; }`.
- **devShells** — development environments via `nix develop .#<name>`.
- **checks** — test derivations run by `nix flake check`.
- **legacyPackages** — full pkgs overlay, typically `pkgs` itself.
- **formatter** — the default formatter package (e.g., `pkgs.nixfmt-rfc-style`).
- **devShell** — default dev shell (shortcut when only one is needed).

### Per-system module arguments

Inside `perSystem = { ... }`:

- **pkgs** — the nixpkgs package set for the current system.
- **system** — the current system string.
- **inputs'** — per-system view of inputs (e.g., `inputs'.nixpkgs.package`).
- **self'** — per-system view of the flake's own outputs (e.g., `self'.packages.foo`).
- **lib** — nixpkgs lib functions.
- **config** — the merged perSystem config.

### withSystem

- `withSystem system ({ self', inputs', pkgs, ... }: ...)` — evaluates a function with per-system context from outside `perSystem`.
- Used in reusable NixOS/Home Manager modules that need to reference the flake's own packages.
- Avoids manual `self.packages.${system}` indexing.

### Reusable modules

- Export via `flake.modules.nixos.<name>` or `flake.modules.homeManager.<name>`.
- Consumers import them in their own flake or NixOS config.
- Use `withSystem` internally for per-system package access.
- The `flake` key can also contribute to `nixosModules`, `homeManagerModules`, `darwinModules`, etc.

### Flake extension pattern

- Other projects (treefmt-nix, nix-wrapper-modules, etc.) expose a `flakeModule` that you import.
- They add their own options to the flake-parts module system.
- You configure them through the options they define, and they contribute to flake outputs.

### Repo source pointers

- Flake-parts module usage lives throughout `modules/`.
- Per-system scope patterns are summarized in [[Scope Boundaries And Per-System Access]].
- Keep concrete examples in source files or upstream docs so this note does not drift.

### Helpful Docs

- Main docs: `https://flake.parts/`
- Option reference: `https://flake.parts/options/flake-parts.html`
- Module arguments: `https://flake.parts/module-arguments.html`
- Exported module docs: `https://flake.parts/options/flake-parts-modules.html`
- Reusable module guide: `https://flake.parts/dogfood-a-reusable-module.html`
- Tutorial: `https://flake.parts/tutorial.html`
- Upstream repo: `https://github.com/hercules-ci/flake-parts`

## Known Quirks

- Do not reach for `self.packages.${system}` from a top-level reusable module when `withSystem` and `self'` are the right fit.
- Do not request NixOS-only module args like `modulesPath` from the outer flake-parts file function.
- Do not fake reusable NixOS module parameters with outer default args unless you also pass them through real module args.
- If something feels like a scope problem, it usually is.
- Related issues: [[2026-04-27: `modulesPath` missing from outer flake-parts module args]], [[2026-04-27: reaching for `self.packages.${system}` instead of `withSystem` and `self'`]], [[2026-04-28: defaulted outer module args still require `_module.args` when reused as NixOS modules]]
