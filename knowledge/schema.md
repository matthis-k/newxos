---
id: memory-schema
type: reference
title: Memory schema
status: active
tags:
- memory
- schema
links:
- agent-rules
updated: 2026-05-11
permalink: newxos/schema
---

# Memory schema

Every Markdown memory file should use YAML frontmatter.

## Observations

- [fact] Required fields: id, type, title, status, tags, links, updated
- [decision] Use folders for topic/domain; use `type` for record kind
- [technique] Use stable IDs in `links`; use wiki links in prose when useful: `[[architecture-flake-file]]`
- [requirement] Do not delete obsolete decisions; mark them `superseded` or `deprecated` and link to replacement

## Relations

- relates_to [[agent-rules]]

## Required fields

```yaml
---
id: stable-id
type: index | concept | decision | issue | task | source | workflow | reference | archive
title: Human-readable title
status: active | draft | accepted | superseded | deprecated | todo | doing | blocked | done | cancelled
tags: []
links: []
updated: YYYY-MM-DD
---
```

## Type rules

Use folders for topic/domain.

Use `type` for record kind.

Examples:

* `architecture/flake-file.md` uses `type: concept`
* `issues/nixos-install-oom.md` uses `type: issue`
* `tasks/basic-memory/package-basic-memory-with-uv2nix.md` uses `type: task`
* `decisions/2026-05-11-local-memory-index.md` uses `type: decision`

## Links

Use stable IDs in `links`.

Use wiki links in prose when useful:

```md
Related: [[architecture-flake-file]]
```

## Status

Do not delete obsolete decisions. Mark them `superseded` or `deprecated` and link to the replacement.
