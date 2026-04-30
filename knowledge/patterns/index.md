# Patterns

Important repo composition patterns.

## Index

- [Dendritic Feature Modules](dendritic-modules.md): small feature-focused modules instead of one central registry.
- [Scope Boundaries And Per-System Access](per-system-scopes.md): how to move between top-level flake scope, `perSystem`, and NixOS or Home Manager modules.
- [Host And User Layout](host-and-user-layout.md): how concrete hosts, shared system modules, and user modules are arranged.
- [Wrapped Programs And Generated Config](wrapped-programs.md): when config belongs in wrappers, in `configs/`, or in generated imports.

## Notes

- Use these pages for repo conventions.
- Use the library pages for upstream tool behavior.
- Use [Encountered Issues](../encountered_issues.md) for mistakes the repo has already paid for.
