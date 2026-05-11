---
title: README
type: note
permalink: newxos/readme
---

# Knowledge

Short repo memory for this flake.

## Map

- [Agent Rules](AGENT_RULES.md): rules for agents working in this repo.
- [Schema](schema.md): memory frontmatter schema and type rules.
- [Tags](tags.md): registered tag vocabulary.
- [Architecture](architecture/README.md): structural design, dendritic pattern, flake-file, import-tree, module layout.
- [Agents](agents/README.md): OpenCode, MCP, Basic Memory, caveman skill, workflows.
- [Nix](nix/README.md): flakes, Home Manager, NixOS modules, packages, overlays, performance.
- [Theming](theming/README.md): Stylix, Catppuccin, Zen Browser, GTK, userChrome.
- [Installation](installation/README.md): low-memory live USB, first install, recovery.
- [Hardware](hardware/README.md): laptop, audio, peripherals.
- [Secrets](secrets/README.md): sops-nix, agenix, age.
- [Issues](issues/README.md): known issues and workarounds.
- [Decisions](decisions/README.md): architecture and process decisions.
- [Tasks](tasks/README.md): durable TODOs and planned work.
- [Sources](sources/README.md): upstream project notes.
- [Archive](archive/README.md): superseded or deprecated notes.

## Legacy files

These files are kept for backward compatibility. New content goes into the structured folders above.

- [Workflow](workflow.md): day-to-day rules, verification, hooks, handoff, and knowledge upkeep.
- [Flake Structure](flake-structure.md): where things belong in this repo.
- [Libraries](libraries/index.md): important upstream tools, what they do here, and where to read more.
- [Patterns](patterns/index.md): repo-specific composition patterns and common ways to wire things together.
- [Encountered Issues](encountered_issues.md): append-only record of mistakes and gotchas (legacy flat file).

## Notes

- Keep this concise.
- Cross-link related pages when a library, pattern, and issue interact.
- Prefer updating the smallest relevant page instead of growing one giant document.
- Basic Memory indexes the whole `knowledge/` tree for semantic search.