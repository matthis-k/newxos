---
title: workflow
type: note
permalink: newxos/workflow
---

# Workflow

Day-to-day rules for working in this repo.

## Source Of Truth

- Trust local repo files and `nix flake show/check "path:$PWD"` over stale notes.
- Use `nixos_nix` as the source of truth for upstream NixOS, Home Manager, darwin, nixpkgs, and related option or package metadata.
- `nixos_nix` does not index arbitrary flake-defined options, so if an upstream flake option lookup comes up empty, check the pinned input source and library docs directly.
- `flake.nix` is generated. Edit `modules/`, not the generated file.
- Related reading: [Flake Structure](flake-structure.md), [flake-file](libraries/flake-file.md), [flake-parts](libraries/flake-parts.md).

## Core Commands

- Enter the dev shell: `nix develop "path:$PWD"`
- Show actual flake outputs: `nix flake show "path:$PWD"`
- Run checks: `nix flake check "path:$PWD"`
- Regenerate the generated root flake: `nix run "path:$PWD#write-flake"`
- Format the repo: `nix run "path:$PWD#fmt"`
- Run the local gate: `nix run "path:$PWD#repo-gate"`
- Install managed git hooks: `nix run "path:$PWD#install-git-hooks"`
- Run the wrapped assistant package: `nix run "path:$PWD#opencode"`
- Rebuild memory index (after doc edits): `newxos memory reindex`
- Reset and rebuild memory (after doc refactor): `newxos memory reset`

## Normal Flow

- Use the `path:$PWD` form for local Nix commands during agent work. Plain `.` can fail in an untracked checkout.
- Check the relevant knowledge page and upstream option docs before adding repo-local overrides; prefer first-class library options when they already cover the behavior.
- If you change `flake-file` declarations, run `nix run "path:$PWD#write-flake"` before `flake show`, `flake check`, or commit.
- If you add or change a flake output, confirm it appears in `nix flake show "path:$PWD"`.
- Stage new files before final `flake show/check` when outputs depend on the git-visible tree.
- Prefer `nix run "path:$PWD#repo-gate"` before handoff when you changed flake wiring or Nix code. It also rewrites the repo-managed Neovim `vim.pack` lockfile when exposed.
- Related reading: [workflow tooling](libraries/workflow-tooling.md), [Scope Boundaries And Per-System Access](patterns/per-system-scopes.md).

## Git And Hooks

- The managed pre-commit hook runs `write-flake -> write nvim pack lockfile -> fmt -> flake check`.
- In a fresh clone, `nix develop "path:$PWD"` gives you the pre-commit dev shell. Otherwise use `nix run "path:$PWD#install-git-hooks"`.
- If Nix garbage collection removes the `pre-commit` binary, the hook will fail with `No such file or directory`. Run `nix run "path:$PWD#install-git-hooks"` to regenerate it.
- If hooks rewrite files, review them, re-stage task-related files, and rerun the commit.
- Stage only task-related files. Avoid broad `git add .` in a dirty worktree.
- If unrelated local edits make isolation difficult, ask before using `git stash`.

## Commit Messages

- Use Conventional Commits 1.0.0 as the repo baseline: `https://www.conventionalcommits.org/en/v1.0.0/`.
- Format commit subjects as `<type>[optional scope][!]: <description>`.
- Use lowercase types. Prefer `feat` for new behavior, `fix` for bug fixes, and `docs`, `refactor`, `test`, `build`, `ci`, `chore`, or `revert` when those fit better.
- Use an optional scope when it clarifies the subsystem, for example `feat(quickshell): ...` or `docs(workflow): ...`.
- Keep the description short and specific. Describe the change outcome, not filler words.
- Add a body only when extra context helps explain why the change exists or what tradeoff it makes. Leave one blank line between the subject and body.
- Mark breaking changes with `!` in the subject, a `BREAKING CHANGE: ...` footer, or both. Use the footer when the migration impact needs explanation.
- Prefer one logical change per commit. If a change wants multiple commit types, split it when practical.

## Secrets And Data Care

- Default to the least invasive inspection that answers the question.
- Do not read or print secret payloads from `secrets/`, `/run/secrets/*`, `/var/lib/sops-nix/key.txt`, SSH private keys, tokens, or similar files unless the user explicitly asks and there is no safer path.
- Prefer checking secret wiring through module declarations, file paths, references, permissions, or public companion files instead of reading the secret value.
- Do not paste secret contents into summaries, commits, comments, or logs.
- Encrypted files under `secrets/` may be moved or wired up as files, but do not decrypt them unless explicitly asked.
- Related reading: [sops-nix](libraries/sops-nix.md).

## Keeping Knowledge Current

- Keep `AGENTS.md` and `opencode.json` aligned with this knowledge layout.
- Update [Flake Structure](flake-structure.md), [Libraries](libraries/index.md), and [Patterns](patterns/index.md) when their guidance changes.
- Update [Encountered Issues](encountered_issues.md) when a mistake is repeatable and worth remembering.
- If a library quirk caused an issue, cross-link the library page, the pattern page, and the issue entry.

## Before Handoff

- Run the relevant verification commands for the changed area.
- Prefer `nix run "path:$PWD#repo-gate"` after Nix or flake workflow changes, unless the task clearly does not need the full gate.
- If you created or modified knowledge files, refresh the memory index:
  - Small edits (a few files, targeted changes): `newxos memory reindex`
  - Structural changes (new directories, major rewrites, type/schema changes): `newxos memory reset`
- Confirm new or renamed outputs appear in `nix flake show "path:$PWD"` when applicable.
- Call out anything you could not verify.
- Mention any knowledge pages you updated if that matters for later work.