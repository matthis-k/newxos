---
name: repo-verification
description: Use before finishing code or docs changes in newxos to choose and run the right checks by changed path and avoid unverifiable handoffs.
---

# Repo Verification

Use this skill near the end of any non-trivial change.

## Principles

- Run narrow checks first, then broader gates when practical.
- Use local flake refs as `"path:$PWD"`, not `.`.
- Do not claim verification unless command output was inspected.
- Report skipped checks and why.
- Do not stage broadly or rely on staged-only hooks in a dirty worktree.

## Check Selection

- `modules/**`: `nix run "path:$PWD#fmt"`, then `nix flake show "path:$PWD"` or targeted build/check.
- Flake-file declarations: `nix run "path:$PWD#write-flake"` before `flake show` or `flake check`.
- New or changed flake outputs: `nix flake show "path:$PWD"`.
- `configs/quickshell/**`: run the repo QuickShell/QML check if available; otherwise use `repo-gate` when practical.
- `configs/hypr/**`: run the Hyprland config check through the repo gate or targeted package/check.
- `configs/nvim/**` or Neovim modules: run the Neovim check through the repo gate or targeted check.
- `docs/**`: run `nix run "path:$PWD#newxos" -- memory reindex`.

## Default Commands

- Format: `nix run "path:$PWD#fmt"`.
- Show outputs: `nix flake show "path:$PWD"`.
- Broad handoff: `nix run "path:$PWD#repo-gate"`.
- Full flake check: `nix flake check "path:$PWD"`.

## Do Not

- Stop after formatting if behavior changed.
- Run destructive cleanup commands as verification.
- Hide warnings or failures in the final response.
