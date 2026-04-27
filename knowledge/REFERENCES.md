# References

External documentation index for heavily used inputs, tools, and configured programs in this repo.

Related repo-specific guidance: [Foundations](FOUNDATIONS.md)

## How To Keep This Current

- Add or update entries when the repo starts depending on a non-trivial input, tool, or configured program.
- Prefer authoritative docs first. If a project does not have formal docs, link the upstream repository.
- Keep entries short: what it is, why it matters here, and the best URL to start from.
- Link related entries from [Encountered Problems](ENCOUNTERED-PROBLEMS.md) when a tool has a history of repeated mistakes.

## Flake Composition

- `flake-parts`: core module system and `perSystem` model used by this flake. Start here for the high-level model, then use the option reference for concrete module keys and merge behavior. `https://flake.parts/`
- `flake-parts` option reference: canonical option index for the schema this repo's flake modules implement, including `imports`, `perSystem`, `flake`, and nested option shapes. `https://flake.parts/options/flake-parts.html`
- `flake-parts` module arguments: canonical reference for `inputs'`, `self'`, `withSystem`, and `moduleWithSystem`, plus the rule that module functions only receive explicitly named arguments. `https://flake.parts/module-arguments.html`
- `flake-parts.modules` docs: reference for publishing typed modules under `flake.modules.<class>.*` and for using `withSystem` from those modules when they need per-system outputs. `https://flake.parts/options/flake-parts-modules.html`
- `flake-parts` reusable-module guide: reference for exporting `flake.flakeModules`, why they cannot be imported back through `self`, and when to use `importApply` to pass local flake scope into a reusable module. `https://flake.parts/dogfood-a-reusable-module.html`
- `flake-file`: generates the root `flake.nix` from repo declarations. `https://flake-file.oeiuwq.com/overview/`
- Dendritic pattern guide: the main reference for the modular flake structure used here, especially the basics, aspect patterns, and comprehensive example. `https://github.com/Doc-Steve/dendritic-design-with-flake-parts`
- Dendritic basics: the reference for feature naming, `flake.modules.<class>.<aspect>`, and `flake-parts.nix` boilerplate placement. `https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Basics#basics-for-usage-of-the-dendritic-pattern`
- Dendritic comprehensive example: the closest reference for how this repo organizes hosts and users as feature directories rather than central registries. `https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Comprehensive_Example#comprehensive-example`
- `import-tree`: helper used to import the `modules/` tree into `mkFlake`. `https://github.com/vic/import-tree`
- `import-tree` docs: reference for recursive import behavior, including the default convention that ignores paths containing `/_`. `https://import-tree.oeiuwq.com`

## Workflow Inputs

- `home-manager`: NixOS and standalone Home Manager modules used for user-level configuration in this repo. `https://nix-community.github.io/home-manager/`
- `disko`: declarative disk layout module used for host storage definitions. Start at the docs index, then use the quickstart, reference guide, and examples when shaping a host layout. `https://github.com/nix-community/disko/blob/master/docs/INDEX.md`
- `disko` quickstart: simplest install flow and first configuration shape. `https://github.com/nix-community/disko/blob/master/docs/quickstart.md`
- `disko` reference: detailed option and CLI reference. `https://github.com/nix-community/disko/blob/master/docs/reference.md`
- `mcp-nixos`: upstream flake providing the packaged MCP server used by the wrapped `opencode` package. `https://github.com/utensils/mcp-nixos`
- `treefmt-nix`: formatting integration used by the repo formatter and pre-commit gate. `https://github.com/numtide/treefmt-nix`
- `git-hooks.nix`: pre-commit hook integration used to install and run the repo gate. `https://github.com/cachix/git-hooks.nix`
- `nix-wrapper-modules`: wrapper helpers used to expose the configured `opencode` package. `https://github.com/BirdeeHub/nix-wrapper-modules`

## Configured Programs

- OpenCode upstream: terminal coding agent used by the wrapped `opencode` package. `https://github.com/anomalyco/opencode`
- OpenCode config docs: config file locations, merge behavior, and the `instructions` setting used in this repo. `https://opencode.ai/docs/config/`
- OpenCode rules docs: `AGENTS.md` behavior, precedence, and external instruction loading. `https://opencode.ai/docs/rules/`
- OpenCode config schema: authoritative schema for the wrapped `opencode` settings. `https://opencode.ai/config.json`
