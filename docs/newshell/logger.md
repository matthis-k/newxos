# Logger — structured logging and scoped traces for newshell

## Logger vs profiler/debugger

- **Logger**: structured event log with levels, categories, and optional scoped traces. Designed for understanding execution flow.
- **Profiler** (`Profiler.qml`): performance measurement — timing, counters, flamegraphs. Overlaps with trace spans but focuses on hot path cost.
- **Debugger** (launcher's debug IPC): interactive state inspection at a point in time.

Use Logger for development understanding and production diagnostics. Use Profiler for performance optimization.

## Installed level vs runtime level

Two-level control separates deployment decisions from runtime decisions:

**Installed level** (init-time, requires reload to raise):
- Functions below this level are never wrapped.
- `traced(...)` returns the original function directly when its level > installedMaxLevel.
- Zero wrapper cost for non-installed traced functions.
- Defaults: `TRACE` in dev mode, `WARN` in production.

**Runtime level** (dynamic via IPC):
- Wrappers installed above check this level at call time.
- If disabled at runtime, wrapper cost is one indirect function call + one level comparison.
- Changed via `logger.setLevel` IPC command without reload.
- Defaults: `DEBUG` in dev mode, `WARN` in production.

## Log levels

| Level | Value | Description |
|-------|-------|-------------|
| OFF   | 0     | No logging |
| FATAL | 10    | Unrecoverable errors |
| ERROR | 20    | Recoverable errors |
| WARN  | 30    | Suspicious but not wrong |
| INFO  | 40    | Normal operational messages |
| DEBUG | 50    | Detailed development info |
| TRACE | 60    | Finest-grained events |

A log call is enabled if `level <= runtimeMaxLevel`.
A wrapper is installed if `level <= installedMaxLevel`.

## Lazy payload providers

All log and trace methods accept an optional function as the last argument:

```qml
L.info("query.started", function() {
    return { query: query, revision: ctx.queryRevision }
})
```

The function is **not executed** unless the relevant level is enabled. This avoids expensive summarization on cold paths.

## Traced wrappers

`traced(name, fn, options)` wraps a function with automatic `beginTrace`/`endTrace`:

- Returns `fn` unchanged when its level > installedMaxLevel (zero cost).
- When enabled at install time but disabled at runtime: wraps but does not emit.
- When fully enabled: emits `trace.begin`/`trace.end` events with duration.

Arity-specific variants avoid rest-arguments overhead:

- `traced0(name, fn, options)` — no args (`fn.call(this)`)
- `traced1(name, fn, options)` — one arg (`fn.call(this, a)`)
- `traced2(name, fn, options)` — two args
- `traced3(name, fn, options)` — three args

## Begin/end traces

Manual span control:

```qml
const span = L.beginTrace("scoreCandidates", function() {
    return { candidateCount: candidates.length }
})
try {
    return scoreCandidates(candidates, tokens, ctx)
} finally {
    L.endTrace(span, function() {
        return { outputCount: scored.length }
    })
}
```

`traceFn(name, fn, payloadProvider)` combines begin/end/try/finally:

```qml
return L.traceFn("presentation", function() {
    return decidePresentation(scored, ctx)
})
```

## Tap helper

Returns the value unchanged. Only runs the summarizer when DEBUG level is enabled:

```qml
rows = L.tap("rows.final", rows, function(r) {
    return { count: r.length, keys: r.slice(0, 10).map(function(row) { return row.key }) }
})
```

## Scope

Create a scoped logger with prefix and default options:

```qml
readonly property var L: Logger.scope("launcher.pipeline", {
    category: "launcher"
})
```

The scope object supports: `fatal`, `error`, `warn`, `info`, `debug`, `trace`, `beginTrace`, `endTrace`, `traceFn`, `traced`, `traced0/1/2`, and `tap`.

## Cost model

1. **Non-installed traced function**: no wrapper at all. `traced()` returns `fn` directly.
2. **Installed but runtime-disabled**: one indirect call plus one integer compare per invocation.
3. **Fully enabled**: one ring-buffer append per log/trace event.
4. **Lazy payloads**: provider function executed only when level is enabled.
5. **`collect`/`report`**: expensive aggregation only on explicit IPC call.
6. **Ring buffers**: bounded at configurable maxEvents/maxPayloads; old entries silently overwritten.
7. **Reactive bindings**: logging never triggers expensive reactive re-evaluation.

## IPC commands

```bash
newshell ipc logger handle '{"op":"status"}'
newshell ipc logger handle '{"op":"setLevel","level":"trace"}'
newshell ipc logger handle '{"op":"disable"}'
newshell ipc logger handle '{"op":"reset"}'
newshell ipc logger handle '{"op":"collect","includeEvents":true,"includeCounts":true}'
newshell ipc logger handle '{"op":"report","slowMs":4,"top":30}'
```

### Request shapes

```json
{"op": "status"}
{"op": "setLevel", "level": "trace"}
{"op": "disable"}
{"op": "reset"}
{"op": "collect", "includeEvents": true, "includeCounts": true, "limit": 500}
{"op": "report", "slowMs": 4, "top": 30}
```

### Response shape

All responses include `ok: true/false` and optionally `error: "message"`.

## Source files

- `services/Logger.qml` — public API singleton
- `services/logger/LogStore.qml` — ring-buffer event store
- `services/logger/LogStats.qml` — aggregation, report, trace tree
- `services/logger/LoggerIpc.qml` — IPC dispatcher

## Usage examples

```qml
// In any QML file
import qs.services

readonly property var L: Logger.scope("launcher.pipeline", {
    category: "launcher"
})

readonly property var runQuery: L.traced2("runQuery", function(query, ctx) {
    L.info("query.started", function() { return { query: query } })
    return runQueryImpl(query, ctx)
})

// Guarded hot path
if (Logger.debugOn) {
    L.debug("expensive.debug", function() { return computeDebugInfo() })
}

// Assignment with summary (when debug is on)
rows = L.tap("rows.final", rows, function(r) { return { count: r.length } })
```
