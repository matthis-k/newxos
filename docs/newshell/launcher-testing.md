# Launcher tests

The launcher behavior contract lives in:

- `tests/launcher/cases/*.json` — canonical test cases
- `tests/launcher/schemas/launcher-test.schema.json` — case schema

Run all deterministic launcher checks with `repo-gate launcher`:

```sh
repo-gate launcher
```

## Source of truth

- `tests/launcher/cases/*.json` — canonical test cases
- `tests/launcher/schemas/launcher-test.schema.json` — case schema
- `configs/newshell/launcher/` — launcher implementation (source of truth for behavior)

## Commands

| Command | What it runs |
|---------|-------------|
| `repo-gate launcher` | Validate all launcher test cases against schema |
| `repo-gate newshell-cases` | Same as `launcher` |
| `repo-gate newshell-runtime` | Headless compositor boot + optional IPC tests |
| `repo-gate newshell` | `newshell-static` + `newshell-cases` + `newshell-runtime` |
| `repo-gate all` | Full gate including launcher case validation |

## IPC test runner

The `newshell-launcher-test` binary (Rust) reads `tests/launcher/cases/` and drives the launcher via semantic IPC commands (`reset`, `open`, `setQuery`, etc.). Assertions check the launcher's `visualState` output.

```sh
newshell-launcher-test validate tests/launcher/cases
newshell-launcher-test run tests/launcher/cases --mode headless
newshell-launcher-test list tests/launcher/cases
```

## Adding a case

Append to an existing file in `tests/launcher/cases/` or create a new one. Use `absent` to assert a row should not appear and `invariants` for cross-cutting checks:

```json
{
  "name": "audio children selectable, parent not",
  "tags": ["audio", "selection"],
  "steps": [
    { "do": { "type": "reset" } },
    { "do": { "type": "open", "visible": false } },
    { "do": { "type": "setQuery", "query": "audio" } },
    {
      "expect": {
        "exactlyOneSelected": true,
        "absent": [{ "title": "Audio", "selectable": true }],
        "invariants": [
          "exactly-one-selected",
          "non-selectable-groups-not-selected"
        ]
      }
    }
  ]
}
```

## CI/hook

- CI (`nix flake check`) runs `checks.check-newshell-cases` — schema validation of all test cases.
- Pre-commit hook runs `check-newshell-cases` when `tests/launcher/` files change.
- `repo-gate launcher` is the canonical command used by both hook and CI.
