# Launcher decision model

## Pipeline

```
Pipeline stage → decision kind → decider → policy votes → final decision
```

## Policy vote shape

Structural policies (expand, retainParent, nesting, takeoverAccept, defaultAction, riskGate) return normalized votes:

```js
{
  decision: any,       // The policy's decision payload
  priority: number,    // Priority for conflict resolution
  reasons: [           // Traceable justification
    { code: string, text: string, data?: object }
  ]
}
```

`PolicyChain.normalizePolicyResult(raw, spec)` builds this shape from a raw policy return. If `raw` has a `.decision` field it uses it; otherwise the raw value itself becomes the decision. Priority comes from `raw.priority` if present, else from `spec.priority` (the PolicySpec priority).

## Policy types

| Type | Return shape | Decider mode |
|------|-------------|-------------|
| Evidence | `Array<evidenceItem>` | accumulate |
| Boost | `number` | best-wins |
| Expand | `{ decision: { expand, maxChildren, ... }, priority, reasons }` | first-wins |
| RetainParent | `{ decision: { retain }, priority, reasons }` | first-wins |
| Nesting | `{ decision: { intent, includeChildren, ... }, priority, reasons }` | first-wins |
| TakeoverAccept | `{ decision: { accepted, representation, ... }, priority, reasons }` | first-wins |
| RiskGate | `{ decision: { allowed, mode }, priority, reasons }` | first-wins |
| DefaultAction | `{ decision: { ownerId, actionId }, priority, reasons }` | first-wins |
| TokenFlow | `{ consumed, passed, inherited, reason }` | first-wins |
| TakeoverRequest | `Array<claim>` | accumulate |

## Decider

`DecisionDecider.reduce(kind, votes, options)` reduces normalized votes. Modes:

| Mode | Behavior |
|------|----------|
| `highest-priority` | Highest `priority` wins. Ties preserve profile order (first). |
| `first-wins` | First non-null vote wins. |
| `best-wins` | Highest priority, then value comparison for legacy numeric decisions. |
| `accumulate` | All votes collected as array. |
| `all-and` | Boolean AND across all vote decisions. |
| `all-or` | Boolean OR across all vote decisions. |
| `custom` | User-provided `function(votes, ctx)` reducer. |

## Trace contract

```
PolicyChain writes evaluated votes.
Decider writes aggregate.
Stage writes final.
```

No later stage may overwrite evaluated policy votes. `policyTrace[nodeId].evidence.evaluated` preserves real PolicyChain entries; only `aggregate` and `final` are added.

## Priority resolution

`PolicySpec.priority` from the spec declaration (`["policy-name", { args }, priority]`) acts as the fallback priority when the policy result does not include `priority`. This lets profiles declare relative priority without each policy impl needing to return it.

Default reducer: highest-priority. Tie behavior: first policy in profile order wins.

## Files

| File | Role |
|------|------|
| `PolicyChain.qml` | Runs policy specs, normalizes results, combines votes |
| `DecisionDecider.qml` | Reduces normalized policy votes to a final decision |
| `DecisionTrace.qml` | Records policy execution, aggregate, and final traces |
| `Evaluate.qml` | Orchestrates evidence, scoring, token flow per node |
| `ResultShaping.qml` | Evaluates structural policies, decides placement/shape |
| `TakeoverEngine.qml` | Evaluates takeover claims and accept policies |
| `ActivationGate.qml` | Resolves risk-gate policies for activation |
| `TokenFlow.qml` | Evaluates token flow policies |
