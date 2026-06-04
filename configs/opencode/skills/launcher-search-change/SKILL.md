---
name: launcher-search-change
description: Use when changing launcher backends, tokenization, evidence, scoring, flattening, row DTOs, prefix gating, async search, or launcher result rendering.
---

# Launcher Search Change

Use this skill for search behavior in `configs/quickshell/launcher/`.

## Inspect First

- Read launcher architecture in `docs/architecture.md`.
- Read launcher anti-patterns in `docs/contracts/quickshell-design.md`.
- Read ranking expectations in `docs/test-cases/launcher-ranking.md`.
- Read launcher pitfalls in `docs/pitfalls.md`.
- Inspect the owning backend or logic file before editing.

## Architecture Boundary

- Backends produce normalized tree DTOs or result inputs.
- Composite search owns indexing, candidate collection, evidence, scoring, flattening, and row generation.
- Result rows carry primitive fields, actions, and evidence metadata only.
- UI delegates render normalized rows; they do not recompute scoring or hold backend references.
- Prefix gating controls backend participation through `canHandle(query)`.
- Async backends must respect generation counters before applying results.

## Procedure

1. Identify whether the change is backend input, scoring/evidence, flattening, row DTO, or UI rendering.
2. Keep data crossing boundaries plain and serializable.
3. Preserve web fallback behavior: explicit web prefixes or no visible non-web results.
4. Avoid broad rewrites; change the smallest owner.
5. Check ranking expectations after behavior changes.

## Regression Queries

Run or manually inspect the checklist in `docs/test-cases/launcher-ranking.md`, especially:

- `zen`, `zen priv`, `zen win`, `wifi`, `wifi on`, `wo`, `wt`.
- `:`, `:wifi`, `@apps`, `@apps zen`.
- `db wifi`, `dashboard wifi`, `notes`, `/tmp`.

## Do Not

- Keep whole evaluated trees in result rows.
- Treat permission alone as evidence of relevance.
- Prewarm backends whose source model populates asynchronously.
- Let web fallback compete when non-web visible rows exist.
