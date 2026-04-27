# AGENTS

## Structure
- This repo is a minimal `flake-file` + `flake-parts` wrapper, not a conventional app/library tree.
- `flake.nix` is generated. Its header says `DO-NOT-EDIT`; regenerate it with `nix run "path:$PWD#write-flake"`.
- The real local source of truth is `modules/`; local workflow/tooling also lives there.
- `flake.nix` wires `inputs.flake-file.flakeModules.dendritic` into `flake-parts.lib.mkFlake` via `inputs.import-tree ./modules`, so most behavior comes from imported modules rather than handwritten root logic.

## Commands
- Enter the default dev shell for normal local work: `nix develop "path:$PWD"`
- Show actual flake outputs: `nix flake show "path:$PWD"`
- Run the flake verification checks: `nix flake check "path:$PWD"`
- Regenerate generated flake file after changing flake-file module declarations: `nix run "path:$PWD#write-flake"`
- Format repo files through treefmt: `nix run "path:$PWD#fmt"`
- Run the local pre-commit gate manually: `nix run "path:$PWD#repo-gate"`
- Install the managed pre-commit hook into `.git/hooks`: `nix run "path:$PWD#install-git-hooks"`
- The flake also exposes helper packages `write-inputs` and `write-lock`; inspect them with `nix flake show "path:$PWD"` before using them.

## Workflow Gotchas
- While files are still untracked in a git checkout, plain `nix flake ...` on `.` can fail with `Path 'flake.nix' ... is not tracked by Git`. Use the `path:$PWD` form during local agent work.
- `nix flake check "path:$PWD"` does not install git hooks. In a fresh clone, run `nix develop "path:$PWD"` once before the first commit, or install hooks manually with `nix run "path:$PWD#install-git-hooks"`.
- `nix fmt` on `.` is not reliable in an untracked checkout; use `nix run "path:$PWD#fmt"` during local agent work.
- The installed pre-commit hook runs `write-flake -> fmt -> flake check`; if it rewrites files, re-stage them and re-run the commit.
- CI lives in `.github/workflows/ci.yml` and enforces generated `flake.nix` freshness plus `nix flake check`.
- If docs disagree with local flake outputs or module files, trust the local files and `nix flake show/check`.

## Change Workflow
- In a fresh clone, start with `nix develop "path:$PWD"` if you want hooks installed automatically before the first commit.
- Install the managed hook with `nix run "path:$PWD#install-git-hooks"` before relying on pre-commit enforcement in a fresh clone.
- Use `nix run "path:$PWD#repo-gate"` before handoff when you need the same sequence as pre-commit: regenerate, format, then check.
- If you add or change a flake output, confirm it appears in `nix flake show "path:$PWD"` before submitting the work.
- If you change flake-file declarations, regenerate first with `nix run "path:$PWD#write-flake"`, then re-run `nix flake show/check "path:$PWD"`.
- If a new output depends on newly added files, stage the relevant files before final `flake show/check` so Nix evaluates the same git-visible tree that would be committed.
- Stage only task-related files; avoid broad `git add .` in a dirty worktree.
- If unrelated local edits make isolation difficult, ask before using `git stash`; stashing changes the user's working state.
- If the user asks for commits, prefer small local commits per logical change after verification. Do not rewrite or squash history unless the user asks.
- If a new language or toolchain is added, add its authoritative verification command to the repo workflow and document the exact command here. Prefer integrating new checks into `nix flake check` so the repo keeps one obvious verification entrypoint.

## References
- Dendritic template/pattern reference: `https://github.com/Doc-Steve/dendritic-design-with-flake-parts`
- `flake-file` overview: `https://flake-file.oeiuwq.com/overview/`
- `flake-parts` docs: `https://flake.parts/index.html`
