# Encountered Problems

Append-only repo memory for agent mistakes that are easy to repeat in later sessions. Keep entries short and concrete.

Related knowledge: [Foundations](FOUNDATIONS.md), [References](REFERENCES.md)

## Entry Format

- Date: `YYYY-MM-DD`
- Problem: a short reusable description of the actual issue
- Symptom: what failed or what misleading behavior showed up
- Cause: what was actually wrong
- Fix: what resolved it
- Rule: the durable rule future sessions should follow
- Context: optional task or subsystem where the problem showed up
- Related knowledge: link the relevant sections in `FOUNDATIONS.md` and `REFERENCES.md` when applicable

## Entries

### 2026-04-27: `modulesPath` missing from outer flake-parts module args

- Date: `2026-04-27`
- Problem: requesting `modulesPath` from the outer flake-parts module function for a `flake.modules.nixos.*` declaration
- Symptom: `nix flake check` fails with `attribute 'modulesPath' missing` while evaluating the host module
- Cause: `modulesPath` is a NixOS module-system argument, not an argument automatically available to the outer flake-parts module function
- Fix: define `flake.modules.nixos.<name>` as a NixOS module function when it needs `modulesPath`, `config`, or similar NixOS-only module arguments
- Rule: keep flake-parts arguments and NixOS module arguments separate; request NixOS-only arguments inside the module value, not at the outer file boundary
- Context: adding the generated laptop `hardware-configuration.nix` as a host module
- Related knowledge: [Flake-Parts Usage Here](FOUNDATIONS.md#flake-parts-usage-here), [NixOS Host Layout](FOUNDATIONS.md#nixos-host-layout), [Flake Composition](REFERENCES.md#flake-composition)

### 2026-04-27: reaching for `self.packages.${system}` instead of `withSystem` and `self'`

- Date: `2026-04-27`
- Problem: manually indexing `self.packages.${system}` from a top-level `flake.modules.nixos.*` module
- Symptom: the code works but sidesteps the flake-parts per-system access pattern and makes it easy to mix top-level and per-system scopes incorrectly
- Cause: forgetting that `self'` is only available inside the per-system scope entered through `withSystem`
- Fix: use `withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: ...)` inside the NixOS module and read the package from `self'.packages`
- Rule: in top-level flake modules, use `withSystem` to enter the system scope; inside `perSystem`, use `inputs'` and `self'` instead of manual `${system}` indexing when the per-system view exists
- Context: exposing the wrapped `opencode` package through a reusable NixOS module while keeping unsupported systems non-fatal
- Related knowledge: [Flake-Parts Usage Here](FOUNDATIONS.md#flake-parts-usage-here), [Flake Composition](REFERENCES.md#flake-composition)

### 2026-04-28: defaulted outer module args still require `_module.args` when reused as NixOS modules

- Date: `2026-04-28`
- Problem: using a defaulted outer file/module-function argument like `mainDisk ? "/dev/..."` to parameterize a value exported under `flake.modules.nixos.*`
- Symptom: evaluation succeeds for shallow flake output discovery, but forcing the NixOS module can fail with `attribute 'mainDisk' missing`
- Cause: once the exported value is evaluated by the NixOS module system, `mainDisk` is treated as a module argument and resolved through `_module.args`; the outer default does not behave like a normal local binding there
- Fix: replace the pseudo-parameter with a `let` binding for fixed values, or provide a real NixOS option / explicit `_module.args` when configurability is required
- Rule: do not parameterize exported `flake.modules.nixos.*` modules with ad hoc outer arguments unless you also arrange to pass them explicitly during NixOS module evaluation
- Context: `disko.devices.disk.main.device` in the laptop host filesystem module broke `first-time-install`
- Related knowledge: [Flake-Parts Usage Here](FOUNDATIONS.md#flake-parts-usage-here), [NixOS Host Layout](FOUNDATIONS.md#nixos-host-layout), [Flake Composition](REFERENCES.md#flake-composition)
