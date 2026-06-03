# ADR-0004: Keep knowledge as project index and decision memory

## Status

Accepted

## Context

Some knowledge notes had started to duplicate details that should be read from Nix modules or application config files. This created drift risk when source files changed.

## Decision

Treat `docs/` as indirection from concepts to source locations, ownership rules, and durable decisions. Knowledge entries should answer: "when searching for this concept, where should I look, what owns it, and what durable decisions constrain changes?"

Use source files as the source of truth for exact behavior. Use nearby source comments for small fragile details.

## Consequences

- Agents should search memory first to find the right area, then inspect source for exact behavior.
- Knowledge notes stay concise and structural instead of documenting every current setting.
- Durable decisions, placement rules, recurring issues, and upstream references remain in docs.
- Notes that mirror source should be rewritten into concept indexes or removed.
