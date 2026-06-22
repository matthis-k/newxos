---
name: newshell-debugging
description: Debug Newshell/Quickshell failures after deterministic checks fail. Not a validity checker.
---

# newshell-debugging

Use this when deterministic Newshell/Quickshell checks fail.

## Core rule

Do not decide launcher validity from memory or from this skill.

Validity is determined by:
- git hooks;
- targeted `repo-gate` checks;
- launcher JSON cases;
- the deterministic IPC/runtime harness.

This skill is only for debugging failures and proposing fixes.

## First step: identify the failing check

Run or inspect the exact failing command:

```bash
repo-gate --list
repo-gate newshell
repo-gate newshell-static
repo-gate newshell-cases
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime
```

Do not broaden the scope immediately. Reproduce the smallest failing check first.

## Debugging layers

Work from outermost to innermost:

1. **Selector / hook layer**

   * Did the right `repo-gate` target run?
   * Is the hook calling the intended subcommand?
   * Is the check skipped, gated, or actually failing?

2. **Launch/runtime layer**

   * Did Hyprland start?
   * Did a Wayland socket appear?
   * Did Newshell start?
   * Did the tested instance expose the expected `NEWSHELL_TEST_INSTANCE_ID` and `NEWSHELL_IPC_NAMESPACE`?
   * Did the command time out?

3. **IPC layer**

   * Does `launcher state` return valid JSON?
   * Does `interactJson {"action":"state"}` return an ok envelope?
   * Are calls hitting the namespaced test instance, not the user session?

4. **Model/query layer**

   * Does the query endpoint return stable rows?
   * Does the launcher state settle before assertions run?
   * Is the failure caused by backend data, scoring, grouping, selection, or presentation?

5. **Action/safety layer**

   * In test mode, destructive actions must dry-run.
   * Session mode must not call `activateSelected` unless explicitly opted in.
   * Backend actions that affect the host must be disabled or mocked in test mode.

6. **QML/UI layer**

   * Does `shell.qml` pass strict lint?
   * Are broader QML lint failures import-resolution noise or real syntax/type issues?
   * Is the exported state correct while the delegate visual rendering is wrong?

## Required evidence before proposing a fix

Before proposing code changes, collect:

* exact command;
* exact failing check name;
* stdout/stderr;
* Hyprland log if runtime;
* Newshell test log if runtime;
* generated Hyprland config if runtime;
* failing JSON case name if applicable;
* actual IPC output or visual state;
* expected assertion from the JSON case or harness.

Do not propose architecture changes without this evidence.

## Common commands

```bash
repo-gate --list
repo-gate newshell-static
repo-gate newshell-cases
repo-gate newshell
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate newshell-runtime
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 repo-gate all
```

Through Nix without entering `nix develop`:

```bash
nix run "path:$PWD#repo-gate" -- newshell
nix run "path:$PWD#repo-gate" -- newshell-static
NEWXOS_RUN_NEWSHELL_RUNTIME_TESTS=1 nix run "path:$PWD#repo-gate" -- newshell-runtime
```

## Debugging posture

Prefer the smallest fix that makes the deterministic check pass.

Do not:

* add expected behavior to this skill;
* duplicate JSON cases in prose;
* manually declare behavior valid;
* skip failing checks to get a green gate;
* fall back to the user session when a headless runtime check was requested.

Do:

* add or update JSON cases when behavior expectations change;
* improve logs when failures are opaque;
* isolate the failing layer;
* keep runtime tests namespaced;
* preserve deterministic checks as the source of truth.

## Output format for agents

When reporting back, use:

```md
## Failed check

Command:
`...`

Failing layer:
`selector | launch | runtime | IPC | model | action | QML`

## Evidence

- ...
- ...

## Diagnosis

...

## Proposed fix

- File:
- Change:
- Why:

## Validation

Commands rerun:
- ...
```
