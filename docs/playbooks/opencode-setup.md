# OpenCode setup

This repo exposes OpenCode through Nix so agent tooling is reproducible.

## Ownership

- Wrapper and generated settings: `modules/dev/opencode.nix`.
- Repo-owned skill sources and config fragments: `configs/opencode/`.
- Skill paths scan `configs/opencode/skills/` and the upstream Qt agent skills input.
- Secret provisioning: `modules/common/sops.nix`, host/user wiring.

## Configuration

- `opencode.json` controls stable instruction entrypoints.
- `modules/dev/opencode.nix` is the source of truth for generated settings.
- `configs/opencode/` is for repo-owned OpenCode assets.

## MCP servers

- Server definitions are in `modules/dev/opencode.nix`.
- Current servers: GitHub MCP, nixos MCP, Basic Memory MCP, Qt Documentation MCP.

## Rules

- Add server wiring in `modules/dev/opencode.nix`.
- Keep tokens and command details in source, not in docs.
- GitHub token is provisioned from sops-managed secret, not `gh` auth state.
- Do not auto-import provider auth for `openai` or `opencode`; provider login is user-controlled.
- Keep provider secrets and OAuth tokens out of repo memory and commits.
- Do not print decrypted API keys or OAuth tokens.
- Verify executable paths and package exposure through `nix flake show "path:$PWD"` when changing the wrapper.

## Helpful docs

- OpenCode config: <https://opencode.ai/docs/config/>
- OpenCode rules: <https://opencode.ai/docs/rules/>
- OpenCode upstream: <https://github.com/anomalyco/opencode>
- mcp-nixos: <https://github.com/utensils/mcp-nixos>
- GitHub MCP server: <https://github.com/github/github-mcp-server>
