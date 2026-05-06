# Encountered Issues

Append-only repo memory for repeatable mistakes and gotchas.

## Entry Format

- Date: `YYYY-MM-DD`
- Problem: short reusable description of the actual issue
- Symptom: what failed or what misleading behavior showed up
- Cause: what was actually wrong
- Fix: what resolved it
- Rule: durable rule to follow next time
- Context: optional subsystem or task
- Related knowledge: link the relevant library, pattern, workflow, or structure page

## Entries

### 2026-04-27: `modulesPath` missing from outer flake-parts module args

- Date: `2026-04-27`
- Problem: requesting `modulesPath` from the outer flake-parts file function for a `flake.modules.nixos.*` declaration
- Symptom: `nix flake check` failed with `attribute 'modulesPath' missing` while evaluating the host module
- Cause: `modulesPath` is a NixOS module-system arg, not an arg automatically available to the outer flake-parts file function
- Fix: define `flake.modules.nixos.<name>` as a NixOS module function when it needs `modulesPath`, `config`, or similar NixOS-only args
- Rule: keep flake-parts args and NixOS module args separate; request NixOS-only args inside the module value, not at the outer file boundary
- Context: adding generated hardware config as a host module
- Related knowledge: [flake-parts](libraries/flake-parts.md), [Scope Boundaries And Per-System Access](patterns/per-system-scopes.md), [Host And User Layout](patterns/host-and-user-layout.md)

### 2026-04-27: reaching for `self.packages.${system}` instead of `withSystem` and `self'`

- Date: `2026-04-27`
- Problem: manually indexing `self.packages.${system}` from a top-level `flake.modules.nixos.*` module
- Symptom: the code worked, but it sidestepped the intended flake-parts per-system access pattern and made scope mistakes more likely
- Cause: forgetting that `self'` is only available inside the per-system scope entered through `withSystem`
- Fix: use `withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: ...)` inside the reusable module and read packages from `self'.packages`
- Rule: in top-level reusable modules, use `withSystem` to enter system scope; inside `perSystem`, use `inputs'` and `self'`
- Context: exposing the wrapped `opencode` package through a reusable Home Manager module while keeping unsupported systems non-fatal
- Related knowledge: [flake-parts](libraries/flake-parts.md), [Scope Boundaries And Per-System Access](patterns/per-system-scopes.md)

### 2026-04-28: defaulted outer module args still require `_module.args` when reused as NixOS modules

- Date: `2026-04-28`
- Problem: using a defaulted outer file arg like `mainDisk ? "/dev/..."` to parameterize a value exported under `flake.modules.nixos.*`
- Symptom: shallow flake output discovery worked, but forcing the NixOS module failed with `attribute 'mainDisk' missing`
- Cause: once the exported value was evaluated by the NixOS module system, `mainDisk` was treated as a module arg resolved through `_module.args`; the outer default did not behave like a normal local binding there
- Fix: replace the pseudo-parameter with a local `let` binding for fixed values, or provide a real module option or `_module.args` when configurability is truly needed
- Rule: do not parameterize exported `flake.modules.nixos.*` modules with ad hoc outer args unless you also arrange to pass them during NixOS module evaluation
- Context: `disko.devices.disk.main.device` in a host filesystem module
- Related knowledge: [flake-parts](libraries/flake-parts.md), [Scope Boundaries And Per-System Access](patterns/per-system-scopes.md), [Host And User Layout](patterns/host-and-user-layout.md), [disko](libraries/disko.md)

### 2026-05-05: generic Base16 browser targets can lose semantic contrast intent

- Date: `2026-05-05`
- Problem: relying on generic Base16 slot mapping for Zen Browser theming
- Symptom: contrast looked wrong in places like selected vertical tabs and urlbar suggestion rows even though palette itself was fine
- Cause: full semantic palette got flattened into Base16 slots before browser-specific UI groups were chosen, so contrast-sensitive surfaces lost app-specific intent
- Fix: generate repo-owned Zen Browser CSS directly from `config.stylix.fullPalette.colors` and keep browser UI groups mapped from semantic colors in one place
- Rule: when app theme needs more nuance than Base16 slots provide, disable built-in target CSS and generate repo-owned full-palette target under `modules/stylix/`
- Context: Zen Browser Catppuccin-style theme customization
- Related knowledge: [stylix](libraries/stylix.md), [Wrapped Programs And Generated Config](patterns/wrapped-programs.md), [Workflow](workflow.md)

### 2026-05-06: shell arity guards can bypass documented env fallbacks

- Date: `2026-05-06`
- Problem: requiring too many positional args before a command reaches its documented environment-based defaulting logic
- Symptom: `newxos os switch` printed usage instead of using `NEWXOS_HOST` or reporting that the env var was unset or invalid
- Cause: `os_cmd` required at least two args before parsing optional host position, so the default-host branch was unreachable
- Fix: lower the upfront shell arity check so `switch|boot|build` can run without a positional host and fall through to `default_nixos_host`
- Rule: when a command supports env-backed optional positionals, keep the initial argument-count guard aligned with the truly required args only
- Context: `newxos` wrapper host resolution
- Related knowledge: [nh and nom](libraries/nh-nom.md), [Workflow](workflow.md)

### 2026-05-06: multiline shell snippets can break pipelines inside generated wrappers

- Date: `2026-05-06`
- Problem: interpolating a multiline shell snippet immediately before a pipe in `writeShellScriptBin`
- Symptom: build succeeded far enough to generate the script, but running or checking it failed with `syntax error near unexpected token '|'`
- Cause: the interpolated snippet ended with a newline, so the generated script placed `| next-command` on its own shell line
- Fix: keep the full pipeline structure in one script body, or dispatch by mode with `case` instead of splicing whole commands into pipeline positions
- Rule: do not interpolate free-form multiline shell fragments into the middle of pipelines in generated shell scripts
- Context: Hyprland screenshot helpers
- Related knowledge: [hyprland](libraries/hyprland.md), [Workflow](workflow.md)

### 2026-05-07: `buildEnv` tool bundles cannot safely mix wrapped compiler toolchains

- Date: `2026-05-07`
- Problem: putting both `gcc` and `clang` wrapper packages into one shared `pkgs.buildEnv` tool bundle
- Symptom: the `dev-tools` package failed to build with `two given paths contain a conflicting subpath` for `bin/ld`
- Cause: both wrapper toolchains exported the same linker path into the merged environment
- Fix: keep one compiler toolchain per `buildEnv` bundle, and add only the extra tools that do not collide with that wrapper
- Rule: when building shared tool bundles with `pkgs.buildEnv`, avoid mixing `gcc` and `clang` wrappers unless you split them into separate outputs
- Context: `modules/development/dev-tools.nix`
- Related knowledge: [Workflow](workflow.md)
