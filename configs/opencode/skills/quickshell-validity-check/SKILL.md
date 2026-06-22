---
name: quickshell-validity-check
description: Use deterministic repo checks to validate launcher behavior. Do not validate launcher behavior from memory.
---

# QuickShell Validity Check

## Core Rule

Use deterministic repo checks. Do not validate launcher behavior from memory.

Canonical sources:
- behavior cases: `configs/newshell/launcher/tests/cases/*.json`
- harness: `configs/newshell/launcher/tests/`
- orchestrator: `repo-gate`

## Common Commands

```bash
repo-gate --list
repo-gate newshell
repo-gate newshell-runtime
repo-gate newshell-cases
repo-gate statix newshell-static
repo-gate all
```

## Rules

- Add or update JSON cases in `configs/newshell/launcher/tests/cases/` when behavior expectations change.
- Do not encode expected launcher cases in this skill.
- Do not rely on AI for pass/fail judgment.
- AI may inspect failing logs and propose fixes only.
