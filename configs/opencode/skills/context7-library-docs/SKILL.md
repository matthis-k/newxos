---
name: context7-library-docs
description: Use when a coding task needs current external library, framework, package, SDK, or API documentation, especially when APIs may have changed since model training. Do not use for repo architecture, NixOS/Home Manager options, project memory, secrets, Qt docs, or codebase navigation.
---

# Context7 Library Documentation

Use Context7 only for current external library documentation that is not already better covered by local source, Basic Memory, the NixOS MCP, or the Qt Documentation MCP.

## Use Context7 For

- External library API usage.
- Version-sensitive examples.
- Upstream setup or configuration steps.
- Unfamiliar package APIs.
- Changed or deprecated APIs.
- Code generation that depends on third-party docs.

## Do Not Use Context7 For

- Repo architecture, project decisions, or local conventions.
- NixOS, Home Manager, Darwin, Nixvim, or nixpkgs option lookup.
- Qt or QML API documentation covered by Qt Documentation MCP.
- Secrets or auth wiring.
- Exact behavior already defined in source files.

## Workflow

1. Identify the external library or package.
2. Resolve the Context7 library ID.
3. Query only the relevant topic.
4. Treat returned docs as external reference material, not repo policy.
5. Cross-check generated code against local source patterns before editing.
6. Do not copy large upstream docs into this repository.

## Output Expectations

When Context7 affected an implementation, mention the library ID, topic queried, and any version assumption or uncertainty.
