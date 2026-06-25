# Handoff config contract

## Config file format

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

## Base mode

- `"repo"`: rule patterns are repo-relative (default)
- `"config"`: rule patterns are relative to the directory containing the `.handoff.json` file

## Cwd modes

- `"repo"`: detected repo root
- `"config"`: directory containing the `.handoff.json` that defined this node
- `"invocation"`: process cwd captured when `repo-handoff` started

Resolution order: `step.cwd` → `target.cwd` → `config/defaults.cwd` → `"repo"`

## Groups

```json
{
  "groups": {
    "test": {
      "description": "Strict non-recursive test gate",
      "beforeAll": ["setup-db"],
      "afterAll": ["teardown-db"],
      "children": ["rust", "newshell", "hyprland"]
    }
  }
}
```

- `children`: ordered list of target/group IDs to run
- `beforeAll` (optional): targets to run before any child (setup)
- `afterAll` (optional): targets to run after all children (teardown)

Groups are not executable themselves. Cycles cause config validation failure.

Lifecycle hooks (`beforeAll`/`afterAll`) expand like children but are inserted
before/after the group's children in the execution plan. They must reference
valid target IDs (not groups).

## Targets

### Command targets

```json
{
  "targets": {
    "rust": {
      "type": "command",
      "description": "Run Rust unit tests",
      "cwd": "repo",
      "command": {
        "program": "repo-gate",
        "args": ["rust"]
      },
      "expect": {
        "exit": "success"
      },
      "tags": ["rust", "fast"]
    }
  }
}
```

### Shell command targets

```json
{
  "targets": {
    "nix.show": {
      "type": "command",
      "command": {
        "shell": true,
        "line": "nix flake show \"path:$PWD\""
      },
      "expect": { "exit": "success" }
    }
  }
}
```

### Sequence targets

```json
{
  "targets": {
    "newshell.launcher.strict": {
      "type": "sequence",
      "cwd": "repo",
      "steps": [
        {
          "id": "policy",
          "command": { "program": "repo-gate", "args": ["newshell-policy"] },
          "timeoutSeconds": 300
        }
      ]
    }
  }
}
```

### Manual targets

```json
{
  "targets": {
    "session": {
      "type": "command",
      "manual": true,
      "description": "Manual session test",
      "command": { "program": "repo-gate", "args": ["session"] }
    }
  }
}
```

## Rules

```json
{
  "id": "newshell-launcher-source",
  "description": "Launcher implementation changed",
  "when": {
    "anyChanged": ["configs/newshell/launcher/**"]
  },
  "run": ["newshell.launcher"]
}
```

Supported when clauses:
- `anyChanged`: trigger if any path matches
- `noneChanged`: skip if any path matches
- `allChanged`: trigger only if all paths match

## Expectations

```json
{
  "expect": {
    "exit": "success",
    "exitCode": 0,
    "stdoutContains": ["passed"],
    "stderrNotContains": ["ERROR"],
    "stdoutRegex": ["ok"],
    "stderrNotRegex": ["panic"],
    "verify": {
      "program": "jq",
      "args": ["-e", ".exitCode == 0"],
      "stdin": "resultJson"
    }
  }
}
```

## Merge semantics

- `defaults`: shallow merge, later overrides earlier
- `groups`: map merge by id (duplicates need `"override": true`)
- `targets`: map merge by id (duplicates need `"override": true`)
- `rules`: append in load order
