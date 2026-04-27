# References

External documentation index for heavily used inputs, tools, and configured programs in this repo.

Related repo-specific guidance: [Foundations](FOUNDATIONS.md)

## How To Keep This Current

- Add or update entries when the repo starts depending on a non-trivial input, tool, or configured program.
- Prefer authoritative docs first. If a project does not have formal docs, link the upstream repository.
- Keep entries short: what it is, why it matters here, and the best URL to start from.
- Link related entries from [Encountered Problems](ENCOUNTERED-PROBLEMS.md) when a tool has a history of repeated mistakes.

## Flake Composition

- `flake-parts`: core module system and `perSystem` model used by this flake. `https://flake.parts/`
- `flake-parts` option reference: full option index, including `perSystem`. `https://flake.parts/options/flake-parts.html`
- `flake-file`: generates the root `flake.nix` from repo declarations. `https://flake-file.oeiuwq.com/overview/`
- Dendritic pattern guide: the main reference for the modular flake structure used here, especially the basics, aspect patterns, and comprehensive example. `https://github.com/Doc-Steve/dendritic-design-with-flake-parts`
- `import-tree`: helper used to import the `modules/` tree into `mkFlake`. `https://github.com/vic/import-tree`

## Workflow Inputs

- `mcp-nixos`: upstream flake providing the packaged MCP server used by the wrapped `opencode` package. `https://github.com/utensils/mcp-nixos`
- `treefmt-nix`: formatting integration used by the repo formatter and pre-commit gate. `https://github.com/numtide/treefmt-nix`
- `git-hooks.nix`: pre-commit hook integration used to install and run the repo gate. `https://github.com/cachix/git-hooks.nix`
- `nix-wrapper-modules`: wrapper helpers used to expose the configured `opencode` package. `https://github.com/BirdeeHub/nix-wrapper-modules`

## Configured Programs

- OpenCode upstream: terminal coding agent used by the wrapped `opencode` package. `https://github.com/anomalyco/opencode`
- OpenCode config schema: authoritative schema for the wrapped `opencode` settings. `https://opencode.ai/config.json`
