# Foundations

Repo-specific design and workflow notes for how this flake is structured and how the referenced tools are used here.

Related external docs: [References](REFERENCES.md)

## How To Keep This Current

- Add or update a section when the repo's architecture, composition pattern, or workflow meaningfully changes.
- Capture the essence of how it works in this repo, not a generic tutorial.
- Note workflow or verification consequences that matter during edits.
- Link related entries from [Encountered Problems](ENCOUNTERED-PROBLEMS.md) when a concept has a history of repeated errors.

## Repo Architecture

- This repo is a minimal `flake-file` + `flake-parts` wrapper, not a conventional app or library tree.
- `flake.nix` is generated and marked `DO-NOT-EDIT`; local source of truth lives in `modules/`.
- `flake.nix` wires `inputs.flake-file.flakeModules.dendritic` into `flake-parts.lib.mkFlake` via `inputs.import-tree ./modules`, so behavior mainly comes from imported modules rather than handwritten root logic.
- Verification entrypoints: `nix flake show "path:$PWD"` and `nix flake check "path:$PWD"`.
- External docs: [Flake Composition](REFERENCES.md#flake-composition)

## Flake-Parts Usage Here

- Use plain `inputs` for global flake wiring and metadata.
- Inside `perSystem`, prefer flake-parts' `inputs'` and `self'` for system-specific packages and outputs instead of manually indexing `inputs.<name>.packages.${system}`.
- Flake-parts module functions only receive explicitly named arguments; if a module needs `pkgs`, `inputs'`, or `self'`, include them in the function signature.
- If a system-specific upstream package may not exist on every supported system, guard its presence with the global input plus the explicit `system` argument from `perSystem`, then use the resolved package inside the conditional branch.
- Workflow impact: many evaluation mistakes in this repo come from mixing global flake inputs with the per-system view.
- External docs: [Flake Composition](REFERENCES.md#flake-composition)

### Core Patterns

Use `inputs` for global wiring such as imports:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];
}
```

Use explicit arguments when a module needs them:

```nix
{
  inputs,
  lib,
  self,
  ...
}:
```

Inside `perSystem`, use `inputs'` when the system-specific package is expected to exist:

```nix
perSystem = { inputs', pkgs, ... }: {
  packages.example = pkgs.writeShellScriptBin "example" ''
    exec ${inputs'.some-input.packages.default}/bin/example "$@"
  '';
};
```

Inside `perSystem`, use the explicit `system` argument when the package may not exist on every supported system:

```nix
perSystem = { pkgs, system, ... }:
let
  maybePkg = inputs.some-input.packages.${system} or null;
in
{
  packages = lib.optionalAttrs (maybePkg != null) {
    example = pkgs.writeShellScriptBin "example" ''
      exec ${maybePkg.default}/bin/example "$@"
    '';
  };
};
```

Use `self` or `self'` based on what you are addressing:

```nix
treefmt.projectRoot = builtins.path {
  path = self;
  name = "repo-source";
};

perSystem = { self', ... }: {
  apps.default.program = "${self'.packages.example}/bin/example";
};
```

## Dendritic Module Pattern Here

- The repo uses the dendritic pattern to compose behavior from many small modules under `modules/`.
- The root flake is intentionally thin; expect most repo behavior to be declared in imported modules.
- Organize by concern or feature first, not by one giant central file.
- Keep modules small and composable so a change usually belongs in one nearby place.
- When a behavior spans contexts, look for the smallest shared module or pattern instead of copying logic across hosts or outputs.
- If you are unsure where something lives, start by locating the module that imports or exposes the behavior rather than debugging from the generated root flake.
- Workflow impact: when changing behavior, inspect the relevant module under `modules/` before assuming the root flake is the source of truth.
- External docs: [Flake Composition](REFERENCES.md#flake-composition)

## Template Outputs

- The flake exports two example templates under `flake.templates`: `dendritic-simple-module` and `dendritic-workflow-module`.
- `dendritic-simple-module` is the smallest useful example for adding one focused `perSystem` module with a package and app.
- `dendritic-workflow-module` shows the next step up: keep extra `flake-file` input declarations in their own module, import upstream flake modules at the top level, and expose concrete workflow outputs from `perSystem`.
- Both templates are meant to be read as module-structure examples first and starter flakes second; their READMEs call out the repo's common flake-file and flake-parts mistakes.
- Workflow impact: when adding a new template, expose it from a dedicated module and verify it appears in `nix flake show "path:$PWD"`.

## Flake-File Generation Workflow

- `flake.nix` is generated from flake-file declarations, so edits to flake-file-managed inputs or structure should be made in the local module source and then regenerated.
- After changing flake-file declarations, run `nix run "path:$PWD#write-flake"` before `flake show`, `flake check`, or committing.
- Workflow impact: stale generated output can make local success diverge from CI and hooks.
- External docs: [Flake Composition](REFERENCES.md#flake-composition)

## Local Nix Workflow

- In an untracked checkout, plain `nix flake ...` on `.` can fail because Git does not yet expose all needed files to Nix. Use `path:$PWD` during local agent work.
- `nix fmt` on `.` is not reliable in that state either; use `nix run "path:$PWD#fmt"`.
- The managed pre-commit hook runs `write-flake -> fmt -> flake check`. If it rewrites files, re-stage them and rerun the commit.
- `nix flake check "path:$PWD"` does not install hooks; use `nix develop "path:$PWD"` once in a fresh clone or run `nix run "path:$PWD#install-git-hooks"`.
- CI enforces generated `flake.nix` freshness plus `nix flake check`.
- External docs: [Workflow Inputs](REFERENCES.md#workflow-inputs)

## Wrapped OpenCode Package

- The flake exposes `nix run "path:$PWD#opencode"` as a wrapped OpenCode package with MCP-NixOS preconfigured.
- The MCP server is wired to the packaged executable from the dedicated `mcp-nixos` flake input, so the server version is pinned by the flake lock instead of being resolved at runtime through `uvx`.
- Workflow impact: when changing this package, verify both the package output and the packaged `mcp-nixos` executable path it resolves to on the current system.
- External docs: [Workflow Inputs](REFERENCES.md#workflow-inputs), [Configured Programs](REFERENCES.md#configured-programs)
