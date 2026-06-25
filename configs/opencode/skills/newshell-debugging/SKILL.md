---
name: newshell-debugging
description: Debug Newshell/Quickshell failures. Not a validity checker.
---

# newshell-debugging

## Core rule

One source of truth for launcher behavior: `tests/launcher/cases/`. This skill is procedural only — contains zero behavior cases.

## Commit gating

Changes under `configs/newshell/` trigger the `check-newshell-config` pre-commit hook, which runs `repo-gate --hook newshell`. This includes:

- **newshell-static** — QML lint via `qmllint` (parse/type errors only; import failures are warned but tolerated as CI false positives)
- **newshell-runtime** — boots Newshell in a headless Weston compositor and waits for `"Configuration Loaded"`
- **newshell-cases** — validates canonical launcher case schemas

**Static lint does not prove Newshell launches.** The runtime boot is the launch gate. If a launch failure gets through, inspect the hook entry in `modules/dev/workflow.nix` — the `check-newshell-config` hook must point to `--hook newshell` (or `--hook newshell-runtime`), not `--hook newshell-static`.

## Debug flow

### 1. Run the gate

```bash
repo-gate --list
repo-gate newshell
repo-gate newshell-static
repo-gate newshell-cases
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime
```

### 2. Inspect the failing case

Find the failing case name, then run a probe against the right instance:

```bash
# inspect what cases exist
newshell-launcher-test list tests/launcher/cases --filter <failing>

# derive probe — shows IPC commands + jq filter
newshell-launcher-test probe tests/launcher/cases --filter "<failing case>" --print

# run probe against the instance
newshell-launcher-test probe tests/launcher/cases --filter "<failing case>" --run --verbose
```

### 3. Choose target instance

| Context | Use |
|---|---|
| Dev mode / working tree | Dedicated dev instance with unique `NEWSHELL_IPC_NAMESPACE` |
| Installed service | Only if restarted after config change |
| Headless runtime check | The namespaced instance from the harness — never fall back to user service |

```bash
# global/session
newshell ipc call launcher state
newshell ipc call query pipeline "wifi on"

# namespaced (runtime/dev)
newshell ipc call "$NEWSHELL_IPC_NAMESPACE.launcher" state
newshell ipc call "$NEWSHELL_IPC_NAMESPACE.query" pipeline "wifi on"
```

### 4. Check if other cases were affected

```bash
newshell-launcher-test run tests/launcher/cases --mode headless
newshell-launcher-test run tests/launcher/cases --mode headless --filter <related tag>
```

### 5. Fix

- Fix implementation if the case expectation is correct.
- Fix the canonical JSON case if intended behavior changed.
- Fix derivation logic if the canonical case is right but the generated probe is wrong.

## Debug order when inspecting a case

1. Check logs — QML errors, import failures, backend errors, IPC registration
2. Check IPC — does `launcher state` return valid JSON? Is target namespaced correctly?
3. Check model — probe the case, inspect `visualState`, determine which layer failed
4. Enable detailed logs only after narrowing the failing layer

## Required evidence

* exact command and failing check name;
* stdout/stderr;
* Hyprland/Newshell logs if runtime;
* failing JSON case name;
* actual IPC output/visual state;
* expected assertion from the JSON case.

## Do not

* add behavior expectations to this skill;
* duplicate JSON cases in prose;
* manually declare behavior valid;
* skip failing checks to get a green gate;
* fall back to user session when runtime check was requested.