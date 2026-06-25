# Handoff tests (`repo-handoff`)

`repo-handoff` is the path-aware planner/reporter layer that selects and runs
correctness checks based on changed files. It does not define what the checks
do — existing commands like `repo-gate rust`, `repo-gate newshell-cases-run`,
etc. remain the actual executors.

## Usage

```sh
# Default: changed-file-aware handoff for working tree
repo-handoff

# Staged-only (commit hook mode)
repo-handoff --staged

# Strict full test gate
repo-handoff run test

# Run a subtree
repo-handoff run newshell.launcher

# Show the configured tree
repo-handoff tree
repo-handoff tree newshell.launcher

# List all groups and targets
repo-handoff list

# Explain what would run and why
repo-handoff explain

# Validate the merged config
repo-handoff validate-config

# Print merged config
repo-handoff --print-config

# Dry-run (print plan without executing)
repo-handoff --dry-run

# JSON machine-readable output
repo-handoff --json

# Write JSON report to file
repo-handoff --report .repo-handoff-report.json

# Use explicit config files only
repo-handoff -c .handoff.json -c configs/newshell/.handoff.json
```

Via `repo-gate`:

```sh
repo-gate handoff
repo-gate --staged handoff
repo-gate test
```

Via `newxos`:

```sh
newxos test
```

## Config discovery

Config files are named `.handoff.json` or `*.handoff.json`.
They are discovered using `rg --files` from the repo root.

Discovery order (deterministic):

1. Root `.handoff.json` first
2. Shallower paths before deeper
3. Lexicographic order at the same depth

If `--config/-c` is passed one or more times, auto-discovery is disabled.
If `--no-discover` is passed without `--config`, it errors.

If `rg` is missing, the tool errors with a message instructing to install
ripgrep or pass `--config` explicitly.

## Config merge

Each fragment:

```json
{
  "version": 1,
  "base": "repo",
  "defaults": {},
  "groups": {},
  "targets": {},
  "rules": []
}
```

- `defaults`: shallow merge in load order (later overrides earlier)
- `groups`: map merge by id
- `targets`: map merge by id
- `rules`: append in load order
- Duplicate IDs fail unless `"override": true` is set

Every group, target, and rule remembers which config file defined it.

## Groups and targets

Groups form a tree/subtree model. They are not executable by themselves.
Running a group expands to leaf targets in deterministic order.

Groups support lifecycle hooks:

```json
{
  "groups": {
    "newshell.launcher": {
      "description": "Launcher checks",
      "beforeAll": ["boot-compositor"],
      "afterAll": ["cleanup-compositor"],
      "children": ["newshell.policy", "newshell.launcher-mock", "newshell.launcher-headless"]
    }
  }
}
```

`beforeAll` targets run before any child; `afterAll` targets run after all children.
This is JUnit-style `@BeforeAll`/`@AfterAll` for the group subtree.

```json
{
  "groups": {
    "test": {
      "description": "Strict non-recursive test gate",
      "children": ["rust", "newshell", "hyprland", "neovim"]
    },
    "newshell.launcher": {
      "description": "Launcher checks",
      "children": ["newshell.policy", "newshell.cases", "newshell.cases-run"]
    }
  }
}
```

Targets are either `command` or `sequence`:

```json
{
  "targets": {
    "rust": {
      "type": "command",
      "description": "Run Rust unit tests",
      "command": { "program": "repo-gate", "args": ["rust"] },
      "expect": { "exit": "success" },
      "tags": ["rust", "fast"]
    },
    "newshell.launcher.strict": {
      "type": "sequence",
      "description": "Validate and run launcher headless cases",
      "steps": [
        {
          "id": "policy",
          "command": { "program": "repo-gate", "args": ["newshell-policy"] }
        },
        {
          "id": "cases",
          "command": { "program": "repo-gate", "args": ["newshell-cases"] }
        }
      ]
    }
  }
}
```

### Manual targets

Manual targets are never selected automatically. They only run when explicitly
selected with `--allow-manual` or `run <id>`:

```json
{
  "newshell.session": {
    "type": "command",
    "manual": true,
    "description": "Manual session smoke test"
  }
}
```

## Rules

Rules select groups/targets from changed files:

```json
{
  "id": "newshell-launcher-source",
  "when": { "anyChanged": ["configs/newshell/launcher/**"] },
  "run": ["newshell.launcher"]
}
```

Supported clauses for v1:

- `anyChanged` — one or more paths match
- `noneChanged` — none of the paths match (optional filter)
- `allChanged` — all paths must match (optional; for v1, use `anyChanged`)

## Cwd modes

Each target, step, and verification command supports a working directory mode:

| Mode       | Directory                          |
|------------|------------------------------------|
| `repo`     | Detected repo root                 |
| `config`   | Directory containing `.handoff.json|
| `invocation` | Cwd when `repo-handoff` started |

Resolution order: `step.cwd` → `target.cwd` → `defaults.cwd` → `repo`

## Expectations

Each command or step supports:

```json
{
  "expect": {
    "exit": "success",
    "stdoutContains": ["all checks passed"],
    "stderrNotRegex": ["ERROR|panic"]
  }
}
```

Supported fields:

- `exit`: `"success"` or `"failure"`
- `exitCode`: exact exit code
- `stdoutContains`, `stderrContains`
- `stdoutNotContains`, `stderrNotContains`
- `stdoutRegex`, `stderrRegex`
- `stdoutNotRegex`, `stderrNotRegex`
- `verify`: verification command (see below)

## Verification commands

An expectation may define a verifier:

```json
{
  "expect": {
    "exit": "success",
    "verify": {
      "program": "jq",
      "args": ["-e", ".exitCode == 0"],
      "stdin": "resultJson"
    }
  }
}
```

Supported stdin values: `stdout`, `stderr`, `resultJson` (default), `none`.

Environment variables for verifiers:

- `HANDOFF_TARGET_ID`
- `HANDOFF_STEP_ID`
- `HANDOFF_EXIT_CODE`
- `HANDOFF_STDOUT_FILE`
- `HANDOFF_STDERR_FILE`
- `HANDOFF_RESULT_JSON_FILE`
- `HANDOFF_CONFIG_FILE`
- `HANDOFF_CWD`

## Handoff vs test vs manual/session

| Mode | Command | When to use |
|------|---------|-------------|
| Handoff | `repo-handoff` | Before finishing a task; selects checks from changed files |
| Staged handoff | `repo-handoff --staged` | Before commit (hook mode) |
| Strict full test | `repo-handoff run test` | CI gate, full verification |
| Manual/session | `repo-handoff run newshell.session --allow-manual` | Interactive smoke tests against running user session |

## Live backends

Live system backends (VPN, audio, Bluetooth, user session, real Wayland
compositor) are NOT tested by default. Use mocked/fixture/headless targets
instead. The `newshell.cases-run` target uses a headless Weston compositor
and fixture backends, not real hardware state.

Manual/session targets (like `newshell.session`) test against the running
user service and are excluded from automatic handoff and strict tests.

## Selection semantics

1. Explicit CLI targets/groups
2. `--all` selects group `test`
3. Changed-file rules select targets/groups
4. Expand groups into leaf targets
5. Remove excludes
6. Remove manual targets (unless explicitly selected/allowed)
7. Deduplicate preserving order

If no files changed and no explicit target/group provided, the tool prints
"No changed files; no handoff checks selected." and exits success (unless
`--all` was passed).

## Distributed config

Subsystem-local `.handoff.json` fragments can be placed anywhere in the repo.
For example, a launcher-specific fragment at `configs/newshell/launcher/.handoff.json`
would add rules and targets local to that subsystem. The merge logic joins
them with the root config deterministically.
