# AGENTS

Practical guidance for maintaining this NixOS flake. Durable repo docs live in `knowledge/` and are loaded through `opencode.json`.

## Knowledge Map

- [Knowledge Overview](knowledge/README.md)
- [Workflow](knowledge/workflow.md)
- [Flake Structure](knowledge/flake-structure.md)
- [Libraries](knowledge/libraries/index.md)
- [Patterns](knowledge/patterns/index.md)
- [Encountered Issues](knowledge/encountered_issues.md)

## Data Care

- Do not read or print secret payloads from `secrets/`, `/run/secrets/*`, `/var/lib/sops-nix/key.txt`, SSH private keys, tokens, or similar files unless the user explicitly asks and there is no safer way to solve the task.
- Prefer checking paths, wiring, module references, permissions, filenames, or public companion files instead of reading secret values.
- Do not put secret contents into commits, summaries, comments, PR text, or logs.
- If a command would likely dump secret material, stop and ask first.

## Primary Workflow

Full workflow guidance: [Workflow](knowledge/workflow.md).

Key rules:

- Trust local files and `nix flake show/check "path:$PWD"` over stale notes.
- Use MCP-NixOS or `nixos_nix` as the source of truth for upstream NixOS, Home Manager, darwin, and nixpkgs options or package metadata.
- Use the `path:$PWD` form for local Nix commands during agent work; plain `.` can fail in an untracked checkout.
- If you change flake-file declarations, regenerate first with `nix run "path:$PWD#write-flake"`.
- If you add or change a flake output, confirm it appears in `nix flake show "path:$PWD"` before handoff.
- Use `nix run "path:$PWD#repo-gate"` for the pre-commit flow: regenerate, format, then check.
- Stage only task-related files; avoid broad `git add .` in a dirty worktree.
- Write commit subjects in Conventional Commits form: `<type>[optional scope][!]: <description>`.

## Commands

- Enter the default dev shell: `nix develop "path:$PWD"`
- Show flake outputs: `nix flake show "path:$PWD"`
- Run flake checks: `nix flake check "path:$PWD"`
- Regenerate flake: `nix run "path:$PWD#write-flake"`
- Format files: `nix run "path:$PWD#fmt"`
- Run pre-commit gate: `nix run "path:$PWD#repo-gate"`
- Install git hooks: `nix run "path:$PWD#install-git-hooks"`
- Run wrapped OpenCode: `nix run "path:$PWD#opencode"`
- Rebuild Basic Memory: `newxos memory reindex`
- Reset Basic Memory: `newxos memory reset`
- Helper packages: `write-inputs`, `write-lock`, `write-nvim-pack-lock` (inspect with `nix flake show "path:$PWD"`)

## Knowledge Maintenance

- Keep `AGENTS.md` and `opencode.json` aligned with the knowledge layout.
- Keep [Workflow](knowledge/workflow.md), [Flake Structure](knowledge/flake-structure.md), [Libraries](knowledge/libraries/index.md), and [Patterns](knowledge/patterns/index.md) current.
- Keep [Encountered Issues](knowledge/encountered_issues.md) append-only for repeatable mistakes.
- When a task adds or changes a major tool, update the relevant library page and cross-link any relevant pattern page.
- When a task changes how files should be organized, update [Flake Structure](knowledge/flake-structure.md).
- When a task reveals a repeatable mistake, add a short entry to [Encountered Issues](knowledge/encountered_issues.md) before handoff and cross-link the relevant library or pattern page.
