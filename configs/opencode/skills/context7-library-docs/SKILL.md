---
name: context7-library-docs
description: Use when a coding task needs current external library, framework, package, SDK, or API documentation, especially when APIs may have changed since model training. Do not use for repo architecture, NixOS/Home Manager options, project memory, secrets, Qt docs, or codebase navigation.
---

# Context7 Library Documentation

## Core Rule

Use Context7 only for external library docs not already covered by local source, Basic Memory, NixOS MCP, or Qt Documentation MCP. Never copy large upstream docs into this repo.

## Use For

- External library API usage
- Version-sensitive examples
- Upstream setup or configuration steps
- Unfamiliar package APIs
- Changed or deprecated APIs

## Do Not Use For

- Repo architecture, project decisions, or local conventions
- NixOS, Home Manager, Darwin, Nixvim, or nixpkgs option lookup (use NixOS MCP)
- Qt or QML API documentation (use Qt Documentation MCP)
- Secrets or auth wiring
- Exact behavior already defined in source files

## Workflow

1. Identify the external library.
2. Resolve the Context7 library ID (`context7_resolve-library-id`).
3. Query the relevant topic only (`context7_query-docs`).
4. Treat returned docs as external reference, not repo policy.
5. Cross-check generated code against local source patterns before editing.
6. Do not copy large upstream docs into this repository.

## Output Expectations

When Context7 affected an implementation, note the library ID, topic queried, and any version assumption.

## Done Criteria

- Context7 used only for external library docs.
- Library ID and version assumption noted.
- Generated code cross-checked against local patterns.
