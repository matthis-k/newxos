---
name: repo-verification
description: Use before finishing code or docs changes in newxos to choose and run the right checks by changed path and avoid unverifiable handoffs.
---

# Repo Verification

## Core Rule

Run the narrowest check that covers the change first, then broader gates when practical. Always use `"path:$PWD"` for local flake refs, never `.`.

`repo-gate --list` / `modules/dev/workflow.nix` own exact check definitions.

## Check Selection by Path

| Changed Path | First Check | Then |
|-------------|-------------|------|
| `modules/**` | `repo-gate nix` | `nix flake show "path:$PWD"` |
| Flake-file declarations changed | `repo-gate write-flake` | `nix flake show "path:$PWD"` |
| New or changed flake outputs | `nix flake show "path:$PWD"` | `nix flake check "path:$PWD"` |
| `configs/newshell/**` | `repo-gate newshell` | — |
| `configs/hypr/**` or Hyprland modules | `repo-gate hyprland` | — |
| `configs/nvim/**` or Neovim modules | `repo-gate neovim` | — |
| `docs/**` | `repo-gate docs-index` | `repo-gate repo-doctor` when invariants or paths changed |
| `packages/` or Rust code | `repo-gate rust` | — |
| `tools/handoff/**` or `.handoff.json` | `repo-handoff` | `repo-gate rust` |
| `Any change (handoff)` | `repo-handoff` | — |

## Standard Commands

| Command | Purpose |
|---------|---------|
| `repo-gate --list` | List all available checks and aliases |
| `repo-gate write-flake` | Regenerate `flake.nix`, fail on drift |
| `repo-gate fmt` | Format all files (treefmt) |
| `repo-gate statix` | Auto-fix Nix lint issues |
| `repo-gate flake-check` | Run `nix flake check` |
| `repo-gate repo-doctor` | Run repo invariant checks |
| `repo-gate rust` | Run newxos-cli Rust unit tests |
| `repo-gate newshell` | newshell-static + newshell-cases + newshell-session |
| `repo-gate newshell-runtime` | Headless Hyprland IPC tests (opt-in) |
| `repo-gate hyprland` | Verify Hyprland Lua config |
| `repo-gate neovim` | Verify Neovim starts headless |
| `repo-gate docs-index` | Rebuild Basic Memory index |
| `repo-gate nix` | write-flake + statix + fmt + flake-check |
| `repo-gate quick` | write-flake + fmt + statix + newshell-static |
| `repo-gate all` | Full gate (all except runtime) |
| `repo-gate handoff` | Changed-file-aware handoff via repo-handoff |
| `repo-gate test` | Strict full test gate via repo-handoff |
| `repo-handoff` | Path-aware handoff checks (default: changed files) |
| `repo-handoff --staged` | Staged-only handoff check |
| `repo-handoff run test` | Strict full test gate |
| `repo-handoff tree` | Show configured target/group tree |

## Usage Modes

```bash
# Inside nix develop — zero flake re-evaluation
repo-gate --list
repo-gate newshell statix
repo-gate all
repo-gate handoff
repo-gate test

# From outside — evaluates flake once
nix run "path:$PWD#repo-gate" -- newshell statix
nix run "path:$PWD#repo-gate" -- all

# Staged mode — emulate pre-commit behavior with temp index
repo-gate --staged newshell statix
repo-gate --staged handoff

# Hook mode — run single check for pre-commit framework
repo-gate --hook write-flake
repo-gate --hook pre-commit

# Direct repo-handoff usage
repo-handoff
repo-handoff --staged
repo-handoff run test
repo-handoff tree
```

## repo-handoff selection logic

1. Explicit `--target`/`--group` flags
2. `--all` selects the `test` group
3. Changed-file rules in `.handoff.json` select groups/targets
4. Groups are expanded to leaf targets
5. Manual targets are excluded (unless `--allow-manual`)
6. Exclusions are applied
7. If no files changed and no explicit target: "No changed files; no handoff checks selected."

## Handoff vs test vs manual

| Mode | When |
|------|------|
| `repo-handoff` | Before finishing a task |
| `repo-handoff --staged` | Before commit |
| `repo-handoff run test` | Full strict gate |
| Manual/session | Interactive, opt-in |

## Principles

- Run narrow checks first, broader gates when practical.
- Do not claim verification unless command output was inspected.
- Report skipped checks and why.
- Do not stage broadly or rely on staged-only hooks in a dirty worktree.
- `--staged` mode uses a temporary git index with `git add -A` (like old repo-gate).
- Inside `nix develop`, `repo-gate <checks>` avoids flake re-evaluation.
- Runtime tests are opt-in: set `NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1`.

## Do Not

- Stop after formatting if declarations or outputs changed.
- Run destructive commands as verification.
- Hide warnings or failures.
- Use stale `flake.nix` for `flake show`/`flake check` after declaration changes.

## Done Criteria

- All checks for changed paths passed, or skipped with documented reason.
- `write-flake` run if flake-file declarations changed.
- Formatting applied if code changed.
- `repo-handoff check` passes before handoff.
