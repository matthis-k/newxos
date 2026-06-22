# Maintain the knowledge base

Rules for keeping `docs/` compact, relevant, and durable.

## Target structure

```
AGENTS.md                     # <200 lines, always-relevant operating instructions
docs/
  agent-index.md              # What to read for common task types
  architecture.md             # System shape, components, data flow, invariants
  pitfalls.md                 # Project-specific gotchas and recurring mistakes
  glossary.md                 # Project-specific terminology (if needed)
  testing.md                  # General testing strategy (if needed)
  adr/                        # Accepted architectural decisions (0001-*.md)
  contracts/                  # Interface and compatibility rules (*.md)
  playbooks/                  # Repeatable procedures (*.md)
  test-cases/                 # Detailed expectations and regression cases (*.md)
  debugging/                  # Historical debugging notes with confirmed root cause (*.md)
  ideas.md                    # Speculative, non-authoritative ideas
```

Only create files with useful content. No empty placeholders.

## Classification rules

### Keep in `AGENTS.md`
Only instructions agents must obey on almost every task: build/test/check commands, repo map, coding conventions, architecture invariants, safety rules, workflow, pointers to deeper docs.

### Move to `docs/architecture.md`
Durable system-shape information: components, data flow, layering, ownership boundaries, module relationships, design rationale, cross-cutting invariants.

### Move to `docs/contracts/`
Interface and compatibility rules: backend contracts, API boundaries, QML-facing model expectations, scoring/evidence contracts, IPC contracts. Each contract should explain purpose, required fields, consumers, invariants, non-goals.

### Move to `docs/adr/`
Accepted architectural decisions that future agents might otherwise reverse accidentally. Template: Status, Context, Decision, Consequences, Alternatives considered.

### Move to `docs/pitfalls.md`
Recurring mistakes and gotchas: problem, bad pattern, good pattern, why. Only keep project-specific or repeatedly relevant pitfalls.

### Move to `docs/playbooks/`
Repeatable procedures: how to add a backend, Nix module, test case, etc. Concise and procedural.

### Move to `docs/test-cases/`
Detailed expectations and regression cases for verified behavior.

## Filtering rules

Remove content that is:
- Generic programming advice or motivational text
- Old task prompts or raw chat transcripts
- Outdated debugging logs (no confirmed root cause)
- Duplicated across files
- Copied upstream documentation
- Obvious from code and not easy to misinterpret
- Instructions for tasks no longer relevant
- Speculative ideas mixed into accepted architecture
- Historical one-off postmortems that do not prevent future mistakes

Preserve content that is:
- Project-specific, durable, actionable
- Likely to prevent mistakes
- Expensive to rediscover (>5-10 min)
- Connected to accepted architecture
- Tied to tests, contracts, or invariants
- Likely to cause subtle architectural damage if forgotten

## Goal/Current/Workaround rule

If a documented command, workflow, or behavior is not at its goal state, structure the entry as:

- **Goal**: what the implementation should eventually do
- **Current behavior**: what actually happens now
- **Current workaround**: how to work with current behavior
- **Remove when**: condition that signals the gap is closed

This prevents stale "broken" notes from accumulating and makes it easy to audit what needs cleanup when the condition is met.

## Relevance standard

For every piece of knowledge, ask:
1. Is this still true?
2. Is this specific to this repository?
3. Would a future agent benefit from retrieving it?
4. Is there a clear place where it belongs?
5. Is there a source file or test that supports it?

If unclear, either remove it or mark it `TODO: verify ...`. Do not invent missing facts.

When in doubt, keep only if at least one test passes:
- Would rediscovering this take >5-10 minutes?
- Would forgetting this cause subtle architectural damage?
- Is this a recurring agent mistake?
- Does this encode a stable decision?
- Is it easy to misread the code without this note?

Default action for vague, stale, duplicated, speculative, or generic content is deletion. A smaller accurate KB is better than a large noisy one.
