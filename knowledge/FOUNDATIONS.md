# Foundations

Repo-specific design and workflow notes for how this flake is structured and how the referenced tools are used here.

Related external docs: [References](REFERENCES.md)

## OpenCode Instruction Loading

- `AGENTS.md` stays as the concise, human-readable entrypoint for repo guidance.
- Additional durable rules live under `knowledge/` and are loaded for OpenCode through the root `opencode.json` `instructions` array.
- Keep the Markdown links in `AGENTS.md` even though opencode loads the files separately; the links are for GitHub readability and manual navigation.
- If you rename, move, add, or remove instruction files under `knowledge/`, update both `AGENTS.md` links and `opencode.json`.
- External docs: [Configured Programs](REFERENCES.md#configured-programs)

## How To Keep This Current

- Add or update a section when the repo's architecture, composition pattern, or workflow meaningfully changes.
- Capture the essence of how it works in this repo, not a generic tutorial.
- Note workflow or verification consequences that matter during edits.
- Link related entries from [Encountered Problems](ENCOUNTERED-PROBLEMS.md) when a concept has a history of repeated errors.

## Repo Architecture

- This repo is a minimal `flake-file` + `flake-parts` wrapper, not a conventional app or library tree.
- `flake.nix` is generated and marked `DO-NOT-EDIT`; local source of truth lives in `modules/`.
- `flake.nix` wires `inputs.flake-file.flakeModules.dendritic` into `flake-parts.lib.mkFlake` via `inputs.import-tree ./modules`, so behavior mainly comes from imported modules rather than handwritten root logic.
- Treat the `flake-parts` option reference as the canonical schema for top-level module declarations in this repo; local files under `modules/` are implementations of those documented options.
- Verification entrypoints: `nix flake show "path:$PWD"` and `nix flake check "path:$PWD"`.
- External docs: [Flake Composition](REFERENCES.md#flake-composition)

## Flake-Parts Usage Here

- Use plain `inputs` for global flake wiring and metadata.
- For any top-level key under `imports`, `perSystem`, or `flake`, check the upstream `flake-parts` option reference before inventing new structure; this repo follows that upstream option model.
- If this repo exports reusable flake-parts modules through `flake.flakeModules`, do not import them back through `self`; bind the module value directly and, when it needs local flake scope, pass that scope explicitly with `importApply` or an equivalent `let`-bound module.
- Inside `perSystem`, prefer flake-parts' `inputs'` and `self'` for system-specific packages and outputs instead of manually indexing `inputs.<name>.packages.${system}`.
- When a top-level `flake.modules.*` module needs a per-system package or output, bridge into the system scope with `withSystem` and use `self'` or `config` there instead of reaching for `self.packages.${system}` manually.
- Flake-parts module functions only receive explicitly named arguments; if a module needs `pkgs`, `inputs'`, or `self'`, include them in the function signature.
- Do not use outer file/module-function arguments to parameterize an exported `flake.modules.nixos.*` module unless you also provide them explicitly via `_module.args` or another external caller. Once that value is evaluated by the NixOS module system, names like `mainDisk` are treated as module arguments, and even a defaulted outer argument will still fail if nothing provides it.
- If a `flake.modules.nixos.<name>` value needs NixOS module arguments such as `modulesPath`, `config`, or `lib` from the NixOS module system, make the value itself a NixOS module function rather than requesting those arguments from the outer flake-parts module.
- If a system-specific upstream package may not exist or may refuse evaluation on some supported systems, probe or guard it in `perSystem` before exposing it, and make downstream NixOS modules check whether the corresponding `self'.packages` entry exists.
- Workflow impact: many evaluation mistakes in this repo come from mixing global flake inputs with the per-system view.
- Related problems: [2026-04-27: reaching for `self.packages.${system}` instead of `withSystem` and `self'`](ENCOUNTERED-PROBLEMS.md#2026-04-27-reaching-for-selfpackagessystem-instead-of-withsystem-and-self)
- Related problems: [2026-04-28: defaulted outer module args still require `_module.args` when reused as NixOS modules](ENCOUNTERED-PROBLEMS.md#2026-04-28-defaulted-outer-module-args-still-require-_moduleargs-when-reused-as-nixos-modules)
- External docs: [Flake Composition](REFERENCES.md#flake-composition), especially the `flake-parts` option reference

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

Use `withSystem` when a top-level flake module needs a per-system output:

```nix
{
  withSystem,
  ...
}:
{
  flake.modules.nixos.example =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: lib.optional (self'.packages ? example) self'.packages.example
      );
    };
}
```

## Dendritic Module Pattern Here

- The repo uses the dendritic pattern to compose behavior from many small modules under `modules/`.
- The root flake is intentionally thin; expect most repo behavior to be declared in imported modules.
- The main structural references are the Dendritic Basics and comprehensive example, especially their use of `flake.modules.<class>.<aspect>` and small per-feature modules.
- Organize by concern or feature first, not by one giant central file.
- A feature directory may contain multiple files that all contribute to the same aspect; use filenames like `configuration.nix` or `filesystem.nix` when that split helps readability.
- Keep modules small and composable so a change usually belongs in one nearby place.
- Prefer co-locating closely related NixOS and Home Manager declarations in one file when they describe the same feature or user; split them only when the file stops being easy to read.
- Prefer co-locating tiny flake input and output wrappers with the feature module they expose. Add a separate wrapper file only when the flake-parts logic is substantial enough to justify its own file.
- When a behavior spans contexts, look for the smallest shared module or pattern instead of copying logic across hosts or outputs.
- If you are unsure where something lives, start by locating the module that imports or exposes the behavior rather than debugging from the generated root flake.
- Reusable configuration building blocks live under `flake.modules`, while concrete flake outputs can be exposed directly from the same feature file with upstream constructors such as `inputs.nixpkgs.lib.nixosSystem` and `inputs.home-manager.lib.homeManagerConfiguration`.
- Workflow impact: when changing behavior, inspect the relevant module under `modules/` before assuming the root flake is the source of truth.
- External docs: [Flake Composition](REFERENCES.md#flake-composition)

## Template Outputs

- The flake exports two example templates under `flake.templates`: `dendritic-simple-module` and `dendritic-workflow-module`.
- `dendritic-simple-module` is the smallest useful example for adding one focused `perSystem` module with a package and app.
- `dendritic-workflow-module` shows the next step up: keep extra `flake-file` input declarations in their own module, import upstream flake modules at the top level, and expose concrete workflow outputs from `perSystem`.
- Both templates are meant to be read as module-structure examples first and starter flakes second; their READMEs call out the repo's common flake-file and flake-parts mistakes.
- Workflow impact: when adding a new template, expose it from a dedicated module and verify it appears in `nix flake show "path:$PWD"`.

## NixOS Host Layout

- NixOS systems are exposed from host feature directories under `modules/hosts/<hostname>/`, following the guide's comprehensive-example style instead of using one central host registry file.
- Flake inputs for system modules such as `home-manager` and `disko` live in small root-level feature modules under `modules/` so the input wiring stays close to the module that uses it.
- Each host feature can expose its concrete `nixosConfigurations` output directly from the same file that defines the host module, while sibling files contribute additional host-local concerns when needed.
- Prefer shared root-level `flake.modules.nixos.<aspect>` modules for host-independent system basics such as Nix settings, networking, locales, audio, or sudo policy; concrete hosts should import those shared modules and keep only host-local boot, hardware, storage, and user-linking concerns nearby.
- Installation-media hosts can follow the same pattern: import the upstream NixOS installer module from `inputs.nixpkgs`, keep the concrete ISO host under `modules/hosts/<hostname>/`, and move reusable live-media behavior such as bundled repo content or helper binaries into a shared root-level module.
- Each host owns its imported NixOS modules, including host-local disk layout and user-linking files, instead of pushing those concerns back into a root registry.
- Keep generated hardware modules focused on detected hardware defaults. If storage is managed by `disko`, omit generated `fileSystems`, `swapDevices`, and other duplicate filesystem declarations so `disko` remains the source of truth.
- If a live installer needs to install this flake offline, bundle a filtered copy of the repo into the ISO through `environment.etc` and point installer helpers at that bundled flake path instead of assuming network access or a separate checkout.
- Home Manager user definitions live under `modules/users/<name>/`, and a single nearby file may define both `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>` when those settings are tightly related.
- Concrete systems are exposed directly from feature files with `inputs.nixpkgs.lib.nixosSystem`, and standalone Home Manager configs are exposed with `inputs.home-manager.lib.homeManagerConfiguration`.
- Use the upstream `disko` docs and examples as the reference for layout changes; other local host layouts are examples, not the source of truth.
- Workflow impact: after adding or renaming a host, regenerate `flake.nix`, then verify the new entry shows up under `nixosConfigurations` in `nix flake show "path:$PWD"`.
- Workflow impact: destructive installer helpers should be validated by building their package derivation and evaluating the ISO host, not by executing the install flow during normal repo verification.
- Related problems: [2026-04-27: `modulesPath` missing from outer flake-parts module args](ENCOUNTERED-PROBLEMS.md#2026-04-27-modulespath-missing-from-outer-flake-parts-module-args)
- External docs: [Flake Composition](REFERENCES.md#flake-composition), [Workflow Inputs](REFERENCES.md#workflow-inputs)

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

## Sops-Nix Secret Workflow

- `sops-nix` is the repo's secret-management path for encrypted files that must land on a system or in a user home at activation time.
- Keep `sops` recipient rules in the repo root `.sops.yaml` and store encrypted secret payloads under `secrets/`.
- For this repo's current personal-machine setup, `sops-nix` decrypts with the root-owned `age` key at `/var/lib/sops-nix/key.txt`; that private key stays outside the repo and must be backed up separately.
- Interactive secret editing uses the wrapped `sops` command from this flake, which runs as the normal user but fetches the age identity through `SOPS_AGE_KEY_CMD='sudo cat /var/lib/sops-nix/key.txt'`.
- Store SSH private keys and similar opaque payloads as one-file `binary` secrets and expose them with `sops.secrets.<name>.path` when a program expects a fixed on-disk location.
- Keep non-secret companions such as SSH public keys as normal tracked files when the user needs to copy them into external systems like GitHub.
- Workflow impact: after adding or rotating a secret, re-encrypt the `secrets/` file with `sops`, keep `.sops.yaml` recipients current, and verify with `nix flake check "path:$PWD"`.
- External docs: [Workflow Inputs](REFERENCES.md#workflow-inputs)

## Wrapped OpenCode Package

- The flake exposes `nix run "path:$PWD#opencode"` as a wrapped OpenCode package with MCP-NixOS preconfigured.
- The MCP server is wired to the packaged executable from the dedicated `mcp-nixos` flake input, so the server version is pinned by the flake lock instead of being resolved at runtime through `uvx`.
- Workflow impact: when changing this package, verify both the package output and the packaged `mcp-nixos` executable path it resolves to on the current system.
- External docs: [Workflow Inputs](REFERENCES.md#workflow-inputs), [Configured Programs](REFERENCES.md#configured-programs)

## Wrapper Modules

- This repo can expose configured end-user programs as wrapped `perSystem.packages` built with `nix-wrapper-modules`, then install those packages from NixOS or Home Manager modules with `withSystem` and `self'.packages`.
- Use wrapper packages when a program should carry repo-owned configuration with it, such as the wrapped `opencode`, `kitty`, or `neovim` outputs.
- Prefer the wrapper module path when this repo already exposes one for a program, instead of wiring the raw upstream package directly into host or Home Manager config.
- For `kitty`, keep repo-owned raw config in `configs/kitty/kitty.conf` and feed it into the wrapper via `extraConfig`; use wrapper options such as `font` and `themeFile` when they match the desired shape.
- For `neovim`, prefer `wlib.wrapperModules.neovim` through the exported wrapper and point `settings.config_directory` at the repo config directory under `configs/nvim`.
- Workflow impact: after changing a wrapped package, confirm the relevant package still evaluates through `nix flake show "path:$PWD"` and the consuming host or home configuration still passes `nix flake check "path:$PWD"`.
- External docs: [Workflow Inputs](REFERENCES.md#workflow-inputs)
