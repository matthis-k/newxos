# AGENTS

This agent is a practical assistant for configuring and maintaining this NixOS flake. Durable repo guidance lives in `knowledge/` so it stays easy to browse on GitHub and can be loaded through `opencode.json`.

## Knowledge Map

- [Knowledge Overview](knowledge/README.md)
- [Workflow](knowledge/workflow.md)
- [Flake Structure](knowledge/flake-structure.md)
- [Libraries](knowledge/libraries/index.md)
- [Patterns](knowledge/patterns/index.md)
- [Encountered Issues](knowledge/encountered_issues.md)

## Data Care

- Treat repo data and machine data carefully.
- Do not read or print secret payloads from `secrets/`, `/run/secrets/*`, `/var/lib/sops-nix/key.txt`, SSH private keys, tokens, or similar files unless the user explicitly asks and there is no safer way to solve the task.
- Prefer checking paths, wiring, module references, permissions, filenames, or public companion files instead of reading secret values.
- Do not put secret contents into commits, summaries, comments, PR text, or logs.
- If a command would likely dump secret material, stop and ask first.

## Primary Workflow

- Trust local files and `nix flake show/check "path:$PWD"` over stale notes if they disagree.
- Treat local repo files as the source of truth for this flake's structure and behavior.
- Use MCP-NixOS or `nixos_nix` as the source of truth for upstream NixOS, Home Manager, darwin, and nixpkgs options or package metadata.
- In a fresh clone, start with `nix develop "path:$PWD"` if you want hooks installed automatically before the first commit.
- Use the `path:$PWD` form for local Nix commands during agent work; plain `.` can fail in an untracked checkout.
- If you change flake-file declarations, regenerate first with `nix run "path:$PWD#write-flake"`.
- If you add or change a flake output, confirm it appears in `nix flake show "path:$PWD"` before handoff.
- If a new output depends on newly added files, stage the relevant files before final `flake show/check` so Nix evaluates the same git-visible tree that would be committed.
- Use `nix run "path:$PWD#repo-gate"` before handoff when you want the same sequence as pre-commit: regenerate, format, then check.
- Stage only task-related files; avoid broad `git add .` in a dirty worktree.
- If unrelated local edits make isolation difficult, ask before using `git stash`.
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

- Keep `AGENTS.md` and `opencode.json` aligned with the current knowledge layout.
- Keep [Workflow](knowledge/workflow.md) current for day-to-day repo rules, verification, hooks, handoff, and secure handling.
- Keep [Flake Structure](knowledge/flake-structure.md) current for directory placement rules.
- Keep [Libraries](knowledge/libraries/index.md) current for important upstream tools and repo-specific usage notes.
- Keep [Patterns](knowledge/patterns/index.md) current for composition rules that show up repeatedly.
- Keep [Encountered Issues](knowledge/encountered_issues.md) append-only for repeatable mistakes and gotchas.
- When a task adds or changes a major tool, update the relevant library page and cross-link any relevant pattern page.
- When a task changes how files should be organized, update [Flake Structure](knowledge/flake-structure.md).
- When a task reveals a repeatable mistake, add a short entry to [Encountered Issues](knowledge/encountered_issues.md) before handoff and cross-link the relevant library or pattern page.
