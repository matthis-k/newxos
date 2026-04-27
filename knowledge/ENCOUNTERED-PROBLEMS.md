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
