# AGENTS

Repo-specific workflow for agents lives here. Durable concepts and repo memory live in the linked knowledge files so they stay readable on GitHub:

- [References](knowledge/REFERENCES.md)
- [Foundations](knowledge/FOUNDATIONS.md)
- [Encountered Problems](knowledge/ENCOUNTERED-PROBLEMS.md)

## Primary Workflow
- Trust the local files and `nix flake show/check "path:$PWD"` over stale docs if they disagree.
- Treat local repo files as the source of truth for this flake's structure and behavior, and use MCP-NixOS / `nixos_nix` as the source of truth for upstream NixOS, Home Manager, darwin, and nixpkgs options or package metadata.
- In a fresh clone, start with `nix develop "path:$PWD"` if you want hooks installed automatically before the first commit.
- Use the `path:$PWD` form for local Nix commands during agent work; plain `.` can fail in an untracked checkout.
- If you change flake-file declarations, regenerate first with `nix run "path:$PWD#write-flake"`.
- If you add or change a flake output, confirm it appears in `nix flake show "path:$PWD"` before handoff.
- If a new output depends on newly added files, stage the relevant files before final `flake show/check` so Nix evaluates the same git-visible tree that would be committed.
- Use `nix run "path:$PWD#repo-gate"` before handoff when you want the same sequence as pre-commit: regenerate, format, then check.
- Stage only task-related files; avoid broad `git add .` in a dirty worktree.
- If unrelated local edits make isolation difficult, ask before using `git stash`; stashing changes the user's working state.
- If the user asks for commits, prefer small local commits per logical change after verification. Do not rewrite or squash history unless the user asks.

## Commands
- Enter the default dev shell for normal local work: `nix develop "path:$PWD"`
- Show actual flake outputs: `nix flake show "path:$PWD"`
- Run the flake verification checks: `nix flake check "path:$PWD"`
- Regenerate generated flake file after changing flake-file module declarations: `nix run "path:$PWD#write-flake"`
- Format repo files through treefmt: `nix run "path:$PWD#fmt"`
- Run the local pre-commit gate manually: `nix run "path:$PWD#repo-gate"`
- Install the managed pre-commit hook into `.git/hooks`: `nix run "path:$PWD#install-git-hooks"`
- Run the wrapped OpenCode package with MCP-NixOS preconfigured: `nix run "path:$PWD#opencode"`
- The flake also exposes helper packages `write-inputs` and `write-lock`; inspect them with `nix flake show "path:$PWD"` before using them.

## Knowledge Maintenance
- Keep [References](knowledge/REFERENCES.md) current as a link collection for heavily used inputs, external tools, and configured programs with non-trivial docs.
- Keep [Foundations](knowledge/FOUNDATIONS.md) current for the repo's own design, patterns, workflow constraints, and how those tools are used here.
- Keep [Encountered Problems](knowledge/ENCOUNTERED-PROBLEMS.md) append-only for agent mistakes or recurring gotchas discovered during real tasks.
- When a task adds or changes a major tool, framework, or subsystem, update References with the authoritative external docs and update Foundations with the repo-specific usage, workflow implications, and verification path.
- When a task reveals a repeatable mistake, add a short entry to Encountered Problems before handoff and cross-link the relevant Foundations and References sections.
- When a Foundations or References section accumulates multiple related mistakes, add a `Related problems` line linking the relevant entries in `knowledge/ENCOUNTERED-PROBLEMS.md`.
