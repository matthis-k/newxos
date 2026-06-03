# Basic Memory

Basic Memory provides searchable local project memory for agents.

## Storage model

- Canonical memory is committed as Markdown under `docs/`.
- Generated database, index, cache, and embedding state is local and gitignored under `.cache/basic-memory/`.
- Semantic embeddings use FastEmbed (local, no cloud API).
- Commit Markdown only. Do not commit SQLite, index, cache, or embedding files.

## Commands

```bash
newxos memory reindex  # Rebuild index after doc edits
newxos memory reset    # Reset and rebuild after structural changes
```

## Packaging ownership

- Python workspace: `packages/basic-memory-uv2nix/`.
- Nix packaging and wrapper integration: `modules/dev/opencode.nix`.

## Rules

- Commit Markdown only. Do not commit generated state.
- Do not store secrets in memory.
- Prefer linking existing notes over duplicating content.
- Promote stable, important lessons into topic index pages.
- When updating `packages/basic-memory-uv2nix/uv.lock`, run `nix flake lock` to update `flake.lock`.

## Upstream

- Docs: <https://docs.basicmemory.com>
- Default embedding provider: FastEmbed (local)
