# Launcher Testing

> Validity is determined by deterministic checks, not by reading this document.
>
> See:
> - **Debugging**: `configs/opencode/skills/newshell-debugging/SKILL.md`
> - **Canonical behavior cases**: `tests/launcher/cases/*.json` (via `newshell-launcher-test` binary)
> - **Orchestrator**: `repo-gate newshell` / `NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime`

## Single canonical source

There is exactly one canonical launcher behavior case collection:

```text
tests/launcher/cases/
```

**No behavior cases live under `configs/newshell/launcher/tests/cases/`.** That directory
may contain harness scripts and support files only. All jq-style probes and debug
assertions are derived from the canonical cases — never maintained as a separate collection.

The repo-doctor guard enforces this: source `modules/dev/workflow.nix`.

## Why external tests

Tests are no longer embedded in QML/JS config files or ad-hoc shell scripts.
The launcher exposes semantic control and inspection over IPC, while the standalone
`newshell-launcher-test` binary reads JSON test cases and verifies the launcher state.

```
tests/launcher/cases/*.json
        ↓
newshell-launcher-test
        ↓ semantic IPC
newshell launcher
        ↓
deterministic visualState
        ↓
semantic assertions
```

## How IPC control works

The test runner drives the launcher through semantic IPC commands (`reset`, `open`, `close`, `setQuery`, `typeText`, `backspace`, `moveSelection`, `expandSelected`, `collapseSelected`, `activateSelected`). The launcher exposes `interactionState()` and `visualState()` IPC endpoints for deterministic assertions. The `modelBusy` field tells the runner when the launcher has settled — no fixed sleeps needed.

## Running tests

### Via repo-gate (recommended)

These run the deterministic harness and static checks:

```bash
repo-gate newshell-static              # lint/type-check QML source
repo-gate newshell-cases               # validate canonical JSON case files (no runtime needed)
repo-gate newshell-session             # run canonical cases against running service/session
repo-gate newshell-runtime             # boot in headless compositor, fail on loader errors
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime  # same boot + IPC tests + cases (isolated)
repo-gate newshell                     # static + runtime + cases (no session)
```

Through Nix without entering `nix develop`:

```bash
nix run "path:$PWD#repo-gate" -- newshell-cases
nix run "path:$PWD#repo-gate" -- newshell-session
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 nix run "path:$PWD#repo-gate" -- newshell-runtime
```

### Via newshell-launcher-test binary

Full feature set (step-based cases, fixtures, schema validation):

```bash
# Run cases against current session (like newshell-session)
nix run "path:$PWD#newshell-launcher-test" -- run tests/launcher/cases --mode headless

# Visible mode (manual verification)
nix run "path:$PWD#newshell-launcher-test" -- run tests/launcher/cases --mode visible --filter audio

# Validate test files
nix run "path:$PWD#newshell-launcher-test" -- validate tests/launcher/cases

# List test cases
nix run "path:$PWD#newshell-launcher-test" -- list tests/launcher/cases
nix run "path:$PWD#newshell-launcher-test" -- list tests/launcher/cases --filter wifi
```

## Deriving jq/debug probes from canonical cases

Probes are debugging conveniences derived from canonical cases — not a second
behavior source. Use `newshell-launcher-test probe`:

```bash
# List canonical cases
newshell-launcher-test list tests/launcher/cases

# Show the derived IPC/debug probe for one case
newshell-launcher-test probe tests/launcher/cases --filter "wifi on" --print

# Run one derived probe (shows compact row listing)
newshell-launcher-test probe tests/launcher/cases --filter "wifi on" --run

# Verbose output with full JSON
newshell-launcher-test probe tests/launcher/cases --filter "wifi on" --run --verbose

# Print only the derived jq filter expression
newshell-launcher-test probe tests/launcher/cases --filter "wifi" --print-jq
```

For query-based cases, the probe generates a pipeline command:

```bash
newshell ipc call query pipeline "wifi on" | jq '<derived filter>'
```

For step-based cases, the probe describes the interactJson sequence and final
visual state inspection.

**IPC target rules:**

- For runtime/headless namespaced tests, use `$NEWSHELL_IPC_NAMESPACE`:
  ```bash
  newshell ipc call "$NEWSHELL_IPC_NAMESPACE.launcher" state
  newshell ipc call "$NEWSHELL_IPC_NAMESPACE.query" pipeline "wifi on"
  ```
- For service/session tests, use global targets:
  ```bash
  newshell ipc call launcher state
  newshell ipc call query pipeline "wifi on"
  ```

**Important:**
- Generated jq probes are not persisted as test expectations.
- If a derived jq probe is wrong, fix the canonical case or the derivation logic.
- Do not manually maintain separate jq JSON cases.

## Adding a new canonical case

Add a file to `tests/launcher/cases/` or append to an existing file.

Compact format (single query + expectation):

```json
{
  "name": "wifi on selects correct action",
  "query": "wifi on",
  "expect": {
    "selected": {
      "title": "On",
      "path": ["Actions", "Networking", "Wi-Fi", "On"],
      "executable": true
    },
    "rows": {
      "containsInOrder": ["Networking", "Wi-Fi", "On"]
    }
  }
}
```

Step-based format (multiple actions + assertions):

```json
{
  "name": "desktop app actions only match their own title",
  "tags": ["desktop", "matching"],
  "steps": [
    { "do": { "type": "setQuery", "query": "a" } },
    {
      "expect": {
        "rows": {
          "notContainsTitle": ["New Window"]
        }
      }
    }
  ]
}
```

## Fixture mode

The launcher supports fixture-based deterministic testing via environment variables (`NEWSHELL_TEST_MODE=1`, `NEWSHELL_DESKTOP_FIXTURE`, `NEWSHELL_FILES_FIXTURE`, `NEWSHELL_ACTIONS_FIXTURE`). Source: `tests/launcher/fixtures/` for example files, `configs/newshell/launcher/backends/` for fixture provider logic.

In test mode, `launcher.execute` records `lastExecutedAction` instead of running real side effects.

## visualState.rows ordering

`visualState.rows` is in semantic-test order (navigation tree position), not pixel-exact delegate order. `highlighted === selected` by contract.

## Debugging failures

Do not debug by manually deciding whether launcher behavior is valid. First reproduce the smallest deterministic failing check.

Agents should use:

```text
configs/opencode/skills/newshell-debugging/SKILL.md
```

That skill is procedural only. It does not contain behavior expectations.
