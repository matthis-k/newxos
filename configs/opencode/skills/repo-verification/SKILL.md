---
name: repo-verification
description: Use before finishing code or docs changes in newxos to choose and run the right checks by changed path and avoid unverifiable handoffs.
---

# Repo Verification

## Core Rule

Run the narrowest check that covers the change first, then broader gates when practical. Always use `"path:$PWD"` for local flake refs, never `.`.

## Check Selection by Path

| Changed Path | First Check | Then |
|-------------|-------------|------|
| `modules/**` | `nix run "path:$PWD#fmt"` | `nix flake show "path:$PWD"` |
| Flake-file declarations changed | `nix run "path:$PWD#write-flake"` | `nix flake show "path:$PWD"` |
| New or changed flake outputs | `nix flake show "path:$PWD"` | `nix flake check "path:$PWD"` |
| `configs/newshell/**` | `nix run "path:$PWD#repo-gate"` | — |
| `configs/hypr/**` or Hyprland modules | `nix run "path:$PWD#repo-gate"` | — |
| `configs/nvim/**` or Neovim modules | `nix run "path:$PWD#repo-gate"` | — |
| `docs/**` | `nix run "path:$PWD#newxos" -- memory reindex` | — |

## Standard Commands

| Command | Purpose |
|---------|---------|
| `nix run "path:$PWD#fmt"` | Format all files (treefmt) |
| `nix run "path:$PWD#write-flake"` | Regenerate `flake.nix` |
| `nix flake show "path:$PWD"` | Show all flake outputs |
| `nix flake check "path:$PWD"` | Full flake evaluation + pre-commit hooks |
| `nix run "path:$PWD#repo-gate"` | write-flake → statix → fmt → flake check → hooks |
| `nix run "path:$PWD#newxos" -- memory reindex` | Rebuild Basic Memory index |

## Principles

- Run narrow checks first, broader gates when practical.
- Do not claim verification unless command output was inspected.
- Report skipped checks and why.
- Do not stage broadly or rely on staged-only hooks in a dirty worktree.
- `repo-gate` runs the full hook graph over the whole worktree without requiring staged files.

## Do Not

- Stop after formatting if declarations or outputs changed.
- Run destructive commands as verification.
- Hide warnings or failures.
- Use stale `flake.nix` for `flake show`/`flake check` after declaration changes.

## Done Criteria

- All checks for changed paths passed, or skipped with documented reason.
- `write-flake` run if flake-file declarations changed.
- Formatting applied if code changed.
