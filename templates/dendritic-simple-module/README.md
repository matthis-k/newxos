# Dendritic Simple Module

This template is a minimal `flake-file` + `flake-parts` flake that exists to show how to add one small module without turning the root into a dumping ground.

## Structure

- `flake.nix`: generated output. Treat it as build artifact, not source.
- `modules/dendritic.nix`: enables the dendritic flake-file setup.
- `modules/example-message.nix`: one focused flake-parts module with a package and app.

## Why This Shape

- Put one concern in one nearby module file.
- Let `import-tree` gather modules from `./modules` instead of hand-maintaining a giant import list.
- Keep system-specific outputs in `perSystem` so `flake-parts` can transpose them into normal flake outputs.

## Common Pitfalls

- Do not edit `flake.nix` by hand. Change module source, then run `nix run "path:$PWD#write-flake"` if you changed flake-file declarations.
- Inside `perSystem`, use `self'` for system-qualified outputs. `self` points at the source tree and top-level flake outputs.
- Add module arguments explicitly. If you need `pkgs`, `self'`, or `system`, name them in the function argument set.
- If a feature starts collecting unrelated behavior, split it into another module instead of growing one catch-all file.

## Useful Commands

```sh
nix flake show "path:$PWD"
nix flake check "path:$PWD"
```
