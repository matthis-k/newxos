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
