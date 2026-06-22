# Launcher Testing

> Validity is determined by deterministic checks, not by reading this document.
>
> See:
> - **Debugging**: `configs/opencode/skills/newshell-debugging/SKILL.md`
> - **Lightweight cases**: `configs/newshell/launcher/tests/cases/*.json` (via `repo-gate newshell-cases`)
> - **Full cases**: `tests/launcher/cases/*.json` (via `newshell-launcher-test` binary)
> - **Orchestrator**: `repo-gate newshell` / `NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime`

## Why external tests

Tests are no longer embedded in QML/JS config files or ad-hoc shell scripts.
The launcher exposes semantic control and inspection over IPC, while the standalone
`newshell-launcher-test` binary reads JSON test cases and verifies the launcher state.

```
tests/launcher/*.json
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

The test runner drives the launcher through semantic IPC commands (not keyboard events):

| Command | Effect |
|---|---|
| `reset` | Clear query and state |
| `open` | Show the launcher (headless or visible) |
| `close` | Hide the launcher |
| `setQuery` | Set the search query |
| `typeText` | Append to the query |
| `backspace` | Remove characters from the query |
| `moveSelection` | Move up/down the result list |
| `expandSelected` | Expand the selected result |
| `collapseSelected` | Collapse the selected result |
| `activateSelected` | Execute the selected action |

The launcher exposes `interactionState()` and `visualState()` IPC endpoints that
return deterministic snapshots for assertions. The `modelBusy` field tells the
runner when the launcher has settled after an action — no fixed sleeps needed.

## Running tests

### Via repo-gate (recommended)

These run the deterministic harness and static checks:

```bash
repo-gate newshell-static              # qmllint shell.qml
repo-gate newshell-cases               # lightweight JSON cases (requires running newshell)
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime  # headless IPC + cases
repo-gate newshell                     # static + cases
```

Through Nix without entering `nix develop`:

```bash
nix run "path:$PWD#repo-gate" -- newshell-cases
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 nix run "path:$PWD#repo-gate" -- newshell-runtime
```

### Via newshell-launcher-test binary

Full feature set (step-based cases, fixtures, schema validation):

```bash
# Headless mode (suitable for CI)
nix run "path:$PWD#newshell-launcher-test" -- run tests/launcher/cases --mode headless

# Visible mode (manual verification)
nix run "path:$PWD#newshell-launcher-test" -- run tests/launcher/cases --mode visible --filter audio

# Validate test files
nix run "path:$PWD#newshell-launcher-test" -- validate tests/launcher/cases

# List test cases
nix run "path:$PWD#newshell-launcher-test" -- list tests/launcher/cases
nix run "path:$PWD#newshell-launcher-test" -- list tests/launcher/cases --filter wifi
```

## Adding a new JSON case

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

Lightweight JSON cases (query + jq assertion only) can also be added to:

```text
configs/newshell/launcher/tests/cases/
```

These are run by `repo-gate newshell-cases` via `run-json-cases.sh`.

## Fixture mode

The launcher supports fixture-based deterministic testing via environment variables.
Fixture file paths must be absolute:

```bash
NEWSHELL_TEST_MODE=1
NEWSHELL_DESKTOP_FIXTURE=/path/to/tests/launcher/fixtures/desktop-apps.json
NEWSHELL_FILES_FIXTURE=/path/to/tests/launcher/fixtures/files.json
NEWSHELL_ACTIONS_FIXTURE=/path/to/tests/launcher/fixtures/actions.json
```

When `NEWSHELL_TEST_MODE=1` is set, launcher backends read from fixture files
instead of scanning the host system. This makes tests deterministic in CI
regardless of what apps, files, or network state exist on the machine.

The launcher backend loading code checks test mode early and uses fixture
providers instead of host state. The launcher search/model pipeline does not
care whether nodes came from real providers or fixtures.

### Which backends support fixture mode

| Backend | Fixture source | Behavior in test mode |
|---|---|---|
| `DesktopAppsBackend` | `NEWSHELL_DESKTOP_FIXTURE` | Loads app entries from fixture JSON instead of `DesktopEntries.applications` |
| `DesktopActionsBackend` | `NEWSHELL_ACTIONS_FIXTURE` | Builds action tree from fixture entries; `activate()` is no-op |
| `FilesBackend` | `NEWSHELL_FILES_FIXTURE` | Returns fixture directory listing; `activate()` is no-op |
| `WebSearchBackend` | none | `activate()` is no-op; search results unchanged |
| `CalculatorBackend` | none | Pure computation, already deterministic |

### Fixture file format

**desktop-apps.json** — Array of desktop entry fixtures:
```json
[
  {
    "id": "zen_beta",
    "name": "Zen Browser",
    "desktopName": "zen-beta.desktop",
    "executable": "zen-browser",
    "categories": ["Network", "WebBrowser"],
    "keywords": ["web", "browser"],
    "actions": [
      { "id": "new-window", "name": "New Window" }
    ]
  }
]
```

**actions.json** — Flat action tree entries. Each entry's `path` defines its
position in the action group hierarchy (`["Actions", "Group", "Item", "SubItem"]`):
```json
[
  {
    "id": "networking.wifi.on",
    "title": "On",
    "path": ["Actions", "Networking", "Wi-Fi", "On"],
    "group": "wifi",
    "type": "switch",
    "state": true
  },
  {
    "id": "session.shutdown",
    "title": "Shut Down",
    "path": ["Actions", "Session", "Shut Down"],
    "type": "action",
    "semantics": { "activation": { "requiresConfirm": true } }
  }
]
```

**files.json** — Array of file/directory entries:
```json
[
  { "path": "/home/testuser/Documents", "name": "Documents" }
]
```

## Side-effect safety

In test mode (`NEWSHELL_TEST_MODE=1`), `launcher.execute` does not:
- Launch real applications
- Toggle real network state
- Run arbitrary shell commands

Instead, the visual state records:

```json
{
  "lastExecutedAction": {
    "key": "actions.networking.wifi.on",
    "title": "On"
  }
}
```

Tests can assert on `lastExecutedAction` to verify execution behavior safely.

## Available assertion matchers

### RowMatcher

| Field | Type | Description |
|---|---|---|
| `title` | string | Exact row title match |
| `backend` | string | Backend source (e.g. "desktop", "actions") |
| `placement` | string | Row placement (e.g. "promoted-child", "nested-group") |
| `executable` | boolean | Whether the row can be executed |
| `breadcrumbText` | string | Row breadcrumb context |
| `path` | string[] | Hierarchical path of the row |

### RowsExpectation

| Field | Type | Description |
|---|---|---|
| `count` | number | Exact row count |
| `contains` | RowMatcher[] | At least one row matches each matcher |
| `notContains` | RowMatcher[] | No row matches any matcher |
| `containsTitle` | string[] | At least one row has this title |
| `notContainsTitle` | string[] | No row has this title |
| `containsInOrder` | string[] | Titles appear in this relative order |

## visualState.rows ordering contract

`visualState.rows` is built in a specific semantic order:

* Selectable rows come from the canonical navigation target list, preserving their display order in the navigation tree.
* This includes flattened selectable children emitted immediately after their parent.
* Non-selectable top-level rows are appended at their result-index position, after any selectable nav target for that result.
* Therefore `visualState.rows` is in **semantic-test order**, not necessarily pixel-exact delegate order.
* Tests that need exact visible order should not rely on `containsInOrder` until a dedicated pixel/display-order state is exposed.

This is a deliberate test-model contract — not an accidental implementation detail.

## highlighted semantics

`highlighted` is currently a logical state field on each `VisualRow`:

* `highlighted === selected` by contract — they are derived from the same `activeNodeKey`.
* This catches logical multi-highlight regressions in the exported launcher state.
* It does **not** prove that a QML delegate is not visually painting an ancestor/parent as highlighted via separate styling.
* If pixel/delegate highlight regressions become important, add a separate UI/delegate inspection field or visual regression test later.

## Schema-negative fixtures

Four invalid fixture files live in `tests/launcher/invalid/` to verify that unknown fields are rejected:

| Fixture | What it tests | Caught by |
|---|---|---|
| `unknown-case-field.json` | Typo `titel` at case level | serde + schema |
| `unknown-step-field.json` | Typo `selectors` at step level | serde + schema |
| `unknown-action-field.json` | Typo `queri` inside a StepAction variant | schema only (serde ignores extra fields in internally-tagged enums) |
| `unknown-row-matcher-field.json` | Typo `visble` inside a RowMatcher | serde + schema |

To verify that the schema catches what serde misses:

```bash
nix run "path:$PWD#newshell-launcher-test" -- validate tests/launcher/invalid/unknown-action-field.json \
  --schema tests/launcher/schemas/launcher-test.schema.json
```

This should exit non-zero with a `oneOf` validation error.

## Regression cases

Regression expectations are not listed in this document. They live in the deterministic case files and are executed by the harness through `repo-gate` or the `newshell-launcher-test` binary.

Canonical locations:

```text
tests/launcher/cases/                         # full step-based cases (newshell-launcher-test binary)
configs/newshell/launcher/tests/cases/         # lightweight query→jq cases (run-json-cases.sh / repo-gate)
```

Use:

```bash
repo-gate newshell-cases
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime
```

## Debugging failures

Do not debug by manually deciding whether launcher behavior is valid. First reproduce the smallest deterministic failing check.

Agents should use:

```text
configs/opencode/skills/newshell-debugging/SKILL.md
```

That skill is procedural only. It does not contain behavior expectations.
