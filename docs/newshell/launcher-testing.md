# Launcher tests

The launcher behavior contract lives in:

- `tests/launcher/policies/cases/*.json` — policy unit test cases (fast, deterministic)
- `tests/launcher/cases/*.json` — canonical integration test cases
- `tests/launcher/schemas/` — JSON schemas for test case files
- `configs/newshell/launcher/` — launcher implementation (source of truth for behavior)

## Test taxonomy

### Policy unit tests

Prove policy/reducer/profile semantics with synthetic data. These tests:

- Do not start a real backend.
- Do not call `fd` or touch the real filesystem.
- Use synthetic node DTOs and query DTOs.
- Directly verify policy outputs and reducer decisions.

Files: `tests/launcher/policies/`

| Case file | Covers |
|-----------|--------|
| `policy-chain.json` | `PolicyChain` normalization, reducer modes |
| `decision-decider.json` | `DecisionDecider` vote reduction |
| `token-flow.json` | All registered token-flow policies |
| `evidence-field-match.json` | Field match evidence policy |
| `expand-retain.json` | Expand and retain parent policies |
| `takeover.json` | Takeover request/accept policies |
| `nesting.json` | Nesting policy |
| `profiles.json` | All evaluation profile semantics |
| `file-profile.json` | File profile policy assertions |

```sh
newshell-launcher-test policy validate tests/launcher/policies
newshell-launcher-test policy list tests/launcher/policies
newshell-launcher-test policy run tests/launcher/policies  # requires QML host
```

### Backend/launcher integration tests

Prove backend output can enter the launcher pipeline correctly. These tests:

- Assert that a backend's data can enter the launcher pipeline.
- Do not assert policy internals.
- Do not test real filesystem correctness.
- File backend tests use fixture data in test mode.

Files: `tests/launcher/cases/`

```sh
newshell-launcher-test validate tests/launcher/cases
newshell-launcher-test list tests/launcher/cases
newshell-launcher-test run tests/launcher/cases --mode headless
```

### Runtime visual-state tests

Prove user-visible behavior, navigation, execution, and IPC.

These are the same integration test cases run against a headless compositor with a newshell instance.

## Design rules

- Do not test real filesystem behavior in launcher tests.
- File backend correctness belongs to the backend.
- File launcher semantics belong to `fileProfile` and token-flow policy tests.
- Fixture file tests are allowed only to test launcher integration, not filesystem search correctness.
- Policy unit failures must always fail (unlike runtime tests which may be opt-in).

## Commands

| Command | What it runs |
|---------|-------------|
| `repo-gate launcher-policy` | Validate policy unit test cases (fast, deterministic) |
| `repo-gate launcher-cases` | Validate integration test cases against schema |
| `repo-gate launcher-integration` | Run integration cases against headless newshell |
| `repo-gate launcher` | `launcher-policy` + `launcher-cases` + `launcher-integration` |
| `repo-gate newshell-policy` | Same as `launcher-policy` |
| `repo-gate newshell-cases` | Same as `launcher-cases` |
| `repo-gate newshell-cases-run` | Same as `launcher-integration` |
| `repo-gate newshell-runtime` | Headless compositor boot + optional IPC tests |
| `repo-gate newshell` | `newshell-static` + `newshell-runtime` + `newshell-cases` |
| `repo-gate all` | Full gate including launcher checks |

## IPC test runner

The `newshell-launcher-test` binary (Rust) reads test case directories and drives the launcher via semantic IPC commands (`reset`, `open`, `setQuery`, etc.). Assertions check the launcher's `visualState` output.

```sh
newshell-launcher-test validate tests/launcher/cases
newshell-launcher-test run tests/launcher/cases --mode headless
newshell-launcher-test list tests/launcher/cases
newshell-launcher-test policy validate tests/launcher/policies
newshell-launcher-test policy list tests/launcher/policies
newshell-launcher-test integration validate tests/launcher/cases
newshell-launcher-test all
```

## Adding a case

### Integration case

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

### Policy unit case

Create a file in `tests/launcher/policies/cases/`. Each case must have `name` and `kind` fields:

```json
{
  "cases": [
    {
      "name": "best-wins chooses highest priority",
      "kind": "policyChain",
      "mode": "best-wins",
      "votes": [
        { "decision": 0.3, "priority": 10, "policy": "low", "reasons": [] },
        { "decision": 0.9, "priority": 80, "policy": "high", "reasons": [] }
      ],
      "expect": {
        "selectedPolicy": "high",
        "priority": 80,
        "decision": 0.9
      }
    }
  ]
}
```

## Validation rules

Semantic validation (beyond JSON schema) catches:

- `rows.containsTitle` and `rows.notContainsTitle` must not overlap (same title in both).
- `selected` title should not also be listed in `absent`.
- Unknown invariants fail at assertion time.
- Step-based cases validate every nested `expect`.

## CI/hook

- CI (`nix flake check`) runs `checks.check-newshell-policy` and `checks.check-newshell-cases`.
- Pre-commit hooks run policy checks when `tests/launcher/policies/` files change,
  and integration case checks when `tests/launcher/` files change.
- `repo-gate launcher` is the canonical command used by both hook and CI.
