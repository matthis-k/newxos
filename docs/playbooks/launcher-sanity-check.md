# Launcher sanity check

Use this when changing launcher scoring, flattening, backend participation, row rendering, or IPC-facing result shape.

## Ranking Goals

- Scores are per-node positive evidence scores, not global normalization across all candidates.
- Text evidence should communicate why a row matched: exact, prefix, compact, substring, acronym, fuzzy, semantic, token-policy, switch alias, usage/recency, and path/ancestor evidence.
- More direct/common actions should usually beat rarer or indirect actions unless the query contains evidence for the rare action.
- Parent/group rows should not clutter results with children by default. Show more children when a prefix has no further tokens, the query has a trailing space, or the parent match intentionally exposes direct children.
- Results should be forward stable while typing. If two rows match the same text path, avoid major order shakeups as the query grows.
- Prefixes gate intent. Explicit prefixes can show broader scoped rows; ambient search should stay compact.
- Fuzzy matching should recover likely typos without overwhelming exact/prefix/common matches.

## Stability Examples

These examples are not a fixed regression suite; they describe the underlying rule.

- `networking wifi` and `dashboard wifi` should not randomly trade places while typing `wifi` if both are matching the same visible token.
- `audio` should remain consistently visible across `a`, `au`, `aud`, `audi`, and `audio` instead of appearing only on the final character.
- Common switch actions like Wi-Fi toggle/on/off should beat unrelated lower-frequency actions unless the query names the other action.
- `zen` should prefer the common app/group result, while `zen private` or `zen window` can prefer those specific child actions.

## IPC Debugging

Keep the launcher IPC available for manual checks:

```bash
newshell ipc call query pipeline 'audio'
newshell ipc call query policies 'audio'
newshell ipc call query benchmark '{"queries":["zen","wifi"],"iterations":2}'
newshell ipc call query cases
newshell ipc call query runCases
```

Use `jq` to reduce output before pasting or comparing results:

```bash
newshell ipc call query pipeline 'audio' | jq '.rows[] | select(.ownVisible == true) | {title, subtitle, source, score, ownScore, matchDepth, children: (.children // [] | length)}'
newshell ipc call query pipeline 'audio' | jq '.phases[] | {phase, name}'
newshell ipc call query pipeline 'audio' | jq '.phases[] | select(.name == "evaluation").childScoreBundles[] | {label, score, ownScore}'
newshell ipc call query pipeline 'audio' | jq '.phases[] | select(.name == "shaping").shaped[] | {title, placement, score}'
newshell ipc call query pipeline 'audio' | jq '.backends.entries[] | {id, name, enabled}'
```

Always record the visible query when debugging GUI-only missing-row reports. A row can be absent because the visible launcher query differs from the query sent through IPC, because prefix parsing changed the effective search query, or because the GUI is showing stale/filtered rows.

## Debug Flow for Bad Results

Pipeline modules live in `configs/quickshell/launcher/logic/`: `Evaluate.qml` -> `ResultShaping.qml` (owns placement) -> `RenderedRows.qml` (builds rows from shaped items using `PresentationContext.qml`). `PolicyChain.lookupPolicy` provides normalized spec-aware lookups. TokenFlowDecision not implemented yet; ActionPolicy not extracted.

1. `query pipeline` — universal endpoint. Check rows (`.rows`), phases (`.phases[]`), backends (`.backends`), timings (`.timings`).
   - `.phases[] | select(.name == "directive-tokenize")` — directive, tokens, active backends
   - `.phases[] | select(.name == "evaluation")` — score bundles per backend root
   - `.phases[] | select(.name == "shaping")` — per-item placements
   - `.rows[] | select(.ownVisible == true)` — final rendered rows
2. `query policies` — check normalized policy specs active per kind
3. `query benchmark` — run benchmarks with timing data

## When Logic Changes

- Run the narrow QuickShell check or `nix run "path:$PWD#repo-gate"` when practical.
- Manually sample representative queries with IPC for major search changes.
- Prefer a small set of intent-covering queries over large stored snapshots.
- Compare filtered fields with `jq`; avoid pasting full row payloads unless debugging row shape.
