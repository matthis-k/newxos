# Dendritic Workflow Module

This template shows the next step up from a tiny package module: a focused workflow module that imports upstream flake modules and exposes repo helper commands.

## Structure

- `flake.nix`: generated root flake.
- `modules/dendritic.nix`: enables the dendritic flake-file setup.
- `modules/workflow-inputs.nix`: declares extra flake inputs through `flake-file`.
- `modules/workflow.nix`: imports upstream flake modules and defines workflow outputs.

## Why This Shape

- Input declarations live in their own flake-file module so root wiring changes stay separate from behavior.
- The behavior module owns one concern: formatting and repo checks.
- Upstream flake modules are imported at the top level, while concrete packages and scripts are declared in `perSystem`.

## Common Pitfalls

- If you add or change `flake-file` declarations, regenerate `flake.nix` before `flake show`, `flake check`, or committing.
- Use top-level `inputs` to import upstream flake modules. `inputs'` is for the system-qualified view inside `perSystem`.
- Use `self` for source-tree paths like `treefmt.projectRoot`. Use `self'` only inside `perSystem` when referring to built outputs.
- Prefer `config.treefmt.build.wrapper` and other module outputs over reconstructing tool paths yourself.
- If a pre-commit hook rewrites files, re-stage the rewritten files before the next commit attempt.

## Useful Commands

```sh
nix run "path:$PWD#write-flake"
nix flake show "path:$PWD"
nix flake check "path:$PWD"
```
