---
title: quickshell
type: note
permalink: newxos/libraries/quickshell
---

# quickshell

Quickshell provides the QtQuick/QML shell toolkit used for bars, panels, widgets, and overlays on Wayland.

## Observations

- [fact] Hand-written shell template config lives in `configs/quickshell/`
- [technique] Repo-managed wrapper packages own normal and live-edit launch behavior; read source for exact package names and command lines
- [fact] If pinned `nixpkgs` QuickShell is too old for a new module, update the repo lock before changing imports
- [decision] Leave `.qmlls.ini` untracked next to `shell.qml`; Quickshell manages it per machine for `qmlls` support
- [fact] Breaking changes are expected before 1.0; use upstream migration guides instead of copying old memory notes

## Relations

- relates_to [[Wrapped Programs And Generated Config]]
- relates_to [[Flake Structure]]
- relates_to [[quickshell-design]]

## Repo Usage Index

- Shell source: `configs/quickshell/`.
- Wrapper definitions and package exposure: `modules/desktop/` and `modules/desktop/wrappers/`.
- Theme palette generation: `modules/theming/`.
- Design constraints: [[QuickShell design guidelines]].
- Exact wrapper commands, environment variables, package names, and generated config paths belong in source.

## Basics

- Edit `configs/quickshell/shell.qml` and nearby QML files when changing the repo template.
- Use repo-managed wrappers for normal and source-tree live-edit shell runs; inspect wrapper source for current names and paths.
- If the pinned `nixpkgs` QuickShell is too old for a new module such as `Quickshell.Networking`, update the repo lock before changing imports.
- Leave `.qmlls.ini` untracked next to `shell.qml`; Quickshell manages it per machine for `qmlls` support.
- Related reading: [[Wrapped Programs And Generated Config]], [[Flake Structure]].

## Upstream References

- Guide index: `https://quickshell.org/docs/v0.3.0/guide`
- Install and setup: `https://quickshell.org/docs/v0.3.0/guide/install-setup/`
- QML language reference: `https://quickshell.org/docs/v0.3.0/guide/qml-language/`
- Type reference: `https://quickshell.org/docs/v0.3.0/types`
- QtQuick module docs: `https://doc.qt.io/qt-6/qtquick-qmlmodule.html`
- Upstream mirror: `https://github.com/quickshell-mirror/quickshell`
- Examples: `https://git.outfoxxed.me/outfoxxed/quickshell-examples`

## Known Quirks

- Store-backed wrapper config changes take effect after rebuilding through the normal Home Manager or flake flow.
- Use the source-tree wrapper when iterating on `configs/quickshell/` without rebuilding.
- Keep the template lightweight unless the repo starts managing a fuller shell layout.
- Breaking changes are expected before 1.0; upstream migration guides are the source of truth for API changes.
- `PanelWindow` in particular may not resolve in `qmlls`.

## Launcher Framework

- [fact] Extensible launcher framework source lives in `configs/quickshell/launcher/`.
- [decision] Launcher backends produce normalized semantic results; delegates render only normalized result data.
- [technique] `configs/quickshell/launcher/LauncherController.qml` owns query state, scoring, selection, and backend action routing.
- [fact] The initial launcher backend uses Quickshell `DesktopEntries` for desktop application search and activation.

## Launcher Backends

- [fact] Launcher now includes desktop, calculator, web search, and simple async file-search backends under `configs/quickshell/launcher/backends/`.
- [decision] Explicit launcher prefixes are routed in backend `canHandle` methods so non-target backends do not compete with `=`, `?`, `gh`, `app`, or `file` queries.

## Desktop Entry Terminal Launches

- [fact] Quickshell `DesktopEntry.execute()` ignores `runInTerminal`, so launcher desktop activation must handle terminal entries itself.
- [decision] `DesktopAppsBackend.qml` launches parsed desktop commands through `$TERMINAL -e` when `entry.runInTerminal` is true, with `kitty` as a fallback.

## Launcher Focus And Prefixes

- [fact] Launcher dismissal on Hyprland uses `Quickshell.Hyprland/HyprlandFocusGrab`; do not use unsupported `PanelWindow.onActiveFocusChanged`.
- [decision] Source-selection launcher prefixes use `@app`, `@apps`, `@desktop`, `@calc`, `@calculator`, `@web`, `@file`, and `@files` while retaining older `app`, `file`, `=`, `?`, `g`, `ddg`, `gh`, and `yt` prefixes.

## Launcher Result Limits

- [decision] The launcher separates total collected results from visible rows; the list keeps a fixed-height viewport and scrolls when result count exceeds visible rows.
- [fact] Explicit desktop source queries such as `@app` bypass the desktop backend's default per-backend cap so all desktop entries can be shown in the scrollable list.

## Launcher Web Fallback

- [decision] Web search results are shown only for explicit web prefixes or when non-web backends return no synchronous matches for an unprefixed query.

## Launcher Backend Help

- [fact] `configs/quickshell/launcher/backends/BackendsBackend.qml` owns the launcher source-help backend.
- [decision] The `?` launcher prefix shows available backends and their prefixes; default web search moved to `@web` and named engine prefixes.

## Launcher Prefix Selection

- [decision] Activating a result from the `?` backend-help source replaces the launcher query with that backend's primary prefix and keeps the launcher open for continued input.

## Launcher Backend Metadata

- [decision] Launcher backends can define help metadata such as `helpIcon`, `helpTitle`, `helpDescription`, and `helpPrefixes`; the `?` backend renders those values instead of owning a static list.

## Launcher Composite Search

- [decision] Launcher search uses a composite node pipeline in `configs/quickshell/launcher/logic/CompositeSearch.js`; the older `CommandTree`/`EvidenceScorer` ranking path was removed so backends should implement composite `rootNode(query, context)` plus `activate(result, action)`.
- [fact] `LauncherBackendBase.qml` keeps shared backend metadata and route text helpers; `CommandTreeBackendBase.qml` adapts static action trees into composite nodes for action-style backends.
- [technique] Switch-style actions are represented as one result with `on`, `off`, and `toggle` actions; query tokens choose the best default action, otherwise toggle is the default.
- [fact] Launcher group clarity is handled in delegates with card-like result surfaces and switch controls for switch-capable results.

## Launcher Search Optimizations

- [decision] Static command-tree launcher backends cache their composite root nodes and prepared search indexes between queries.
- [technique] `CompositeSearch.js` caches searchable fields on nodes and stores directive tag closures and per-tree search indexes for exact, prefix, compact, acronym, and term lookup.
- [technique] Per-query evaluation uses index-derived candidate node families to skip direct field matching on nodes that cannot match, while still preserving ancestor/descendant scoring and group visibility.
- [decision] The files backend only participates for raw path queries beginning with `/` or `~`; `@file` and `@files` are no longer file-search selectors.
- [fact] File search results are integrated asynchronously into the composite result model after the gated process backend returns.

## Launcher Performance Fix

- [fact] A composite search optimization bug retained every allowed node as a candidate even without evidence, causing per-keystroke tree retention and high CPU.
- [technique] Candidate retention must require an indexed candidate family, direct evidence, own visibility, or retained children; do not use `selfAllowed` alone as a candidate flag.
- [decision] The launcher candidate index avoids whole-index substring scans on each keystroke; substring evidence only runs for indexed candidate families.

## Launcher Timing IPC

- [fact] Launcher debug timing is exposed through `newshell ipc call launcher debugBenchmark '<json>'`.
- [technique] Benchmark IPC caps work internally and returns per-query timings for root construction, candidate collection, evaluation, path evidence, flattening, candidate counts, and row counts.
- [decision] Composite search must collect candidates from cached backend indexes directly instead of rebuilding and merging a synthetic whole-root index on every keystroke.
- [technique] Static command-tree roots can be prewarmed after startup, but `DesktopAppsBackend` must not prewarm before `DesktopEntries` is populated.

## Launcher File Queries

- [decision] Raw launcher queries beginning with `/` or `~` are reserved for the files backend; ambient web search skips those path-shaped queries unless an explicit web directive such as `@g` is used.
- [technique] Files backend emits a synchronous direct-path row for the typed path and augments it with async `fd` results when available.
- [requirement] Process-backed launcher searches must settle callbacks for both non-empty and empty results to avoid stale pending state.

## Launcher Backend Visibility And File Prefixes

- [decision] Composite backend root nodes are traversal containers only and must never be emitted as launcher result rows.
- [decision] `?` help results are separate backend representation rows from `BackendsBackend`, not the live backend root nodes themselves.
- [decision] Filesystem search only participates for file-shaped prefixes: `file://`, `@file`, `@files`, optional bare `file`/`files`, `~`, or `/`; ordinary ambient queries must not search files.

## Launcher Composite Search Modules

- [decision] Composite launcher search is split into topic modules under `configs/quickshell/launcher/logic/` with `CompositeSearch.js` kept as a small facade for existing QML imports.
- [fact] Module responsibilities are separated into text/query helpers, index building/candidate collection, evidence scoring, tree evaluation/path evidence, UI flattening/result rows, and pipeline orchestration.
- [requirement] Keep the facade API stable for backends and `LauncherController.qml`: `makeNode`, `makeAction`, `buildSearchIndex`, `parseDirective`, `tokenize`, and `search`.

## Launcher Desktop Action Switch Bindings

- [decision] Desktop action boolean switches use generic binding helpers from `configs/quickshell/launcher/backends/CommandTreeBackendBase.qml` instead of bespoke on/off/toggle node wiring.
- [fact] Bound switches expose live `switchState` values from services such as `NetworkService`, `Bluetooth.defaultAdapter`, `NotificationCenter`, and `NordVPN`.
- [technique] `CommandTreeBackendBase.dynamicCompositeRoot` disables composite root caching for backends whose switch state must be read live on each search.

## Launcher Category Group Display

- [decision] Composite search group display supports `showAllChildrenOnParentMatch` in `behavior.flattenPolicy.groupDisplay` so a matching category can render one parent row with nested child actions.
- [fact] Desktop action categories such as Screenshot and Session use this policy so queries like `screen` or `session` show the full action group instead of flattening only the matching child action.
- [technique] Child rows for nested groups are generated by the core flattener; backends only set behavior properties on nodes.

## Launcher Regression Checks

- [technique] Use `newshell ipc call launcher debugSearch '<query>'` after `systemctl --user restart newshell` to verify launcher ranking and default actions.
- [fact] Core checklist: `zen`, `zen `, `zen priv`, `zen win`, `zen browser`, `zen new`, `wifi`, `wifi `, `wifi on`, `wifi off`, `wifi toggle`, `toggle wifi`, `wo`, `wt`, `:`, `:wifi`, `:wifi `, `:wifi on`, `:db wifi`, `@apps`, `@apps zen`, `@apps wifi`, `db wifi`, `dashboard wifi`, `en`, `screen`, `session`, `vpn of`, `notes`, `/tmp`.
- [fact] Expected top/defaults: Zen collapsed for `zen`; Zen children visible for `zen `; private/window actions win for `zen priv`/`zen win`; Wi-Fi defaults to toggle/on/off as queried; `wo`/`wt` select Wi-Fi on/toggle; `:` gates to desktop actions; `@apps` gates to apps; `db wifi` and `dashboard wifi` select Dashboard tab `wifi`; `notes` does not activate files; `/tmp` activates files.

## Launcher Result Collection

- [fact] `configs/quickshell/launcher/tools/collect-debug-search.sh` reads one query per line and emits a single JSON object mapping each query to `newshell ipc call launcher debugSearch` output.
- [technique] Use the helper to compare launcher ranking behavior across iterations with a stable query corpus.

## Launcher Static Tree Backends

- [fact] `configs/quickshell/launcher/backends/StaticTreeBackendBase.qml` adapts nested static action objects into composite launcher backend roots.
- [technique] Static tree nodes can be groups, actions, or boolean switches; executable closures stay inside the backend tree and are resolved at activation through row `metadata.commandPath` plus action id.
- [decision] Launcher debug IPC emits compact normalized row DTOs for diffable search baselines instead of full evidence/action object graphs.

## Launcher Backend Model Hierarchy

- [decision] Launcher backends now use QML base components for object-oriented backend models: `TreeBackendBase`, `ModelTreeBackendBase`, `ComputedBackendBase`, `StreamingBackendBase`, and `ProcessBackendBase`.
- [fact] `TreeBackendBase.qml` adapts nested object trees into composite nodes; `ModelTreeBackendBase.qml` is for model-derived trees such as desktop apps and backend help.
- [fact] `ComputedBackendBase.qml` is for synchronous query-derived results such as calculator and web search.
- [fact] `StreamingBackendBase.qml` owns keyed stream state with add/upsert/remove/reset operations so changing sources can remove stale items instead of only appending.
- [technique] `ProcessBackendBase.qml` derives from `StreamingBackendBase.qml` and resets keyed stream state from parsed process output snapshots.

## Launcher Newxos Actions

- [fact] `DesktopActionsBackend.qml` includes a `Newxos` group with actions for `newxos switch`, `newxos ai`, `newxos git`, `newxos reload_shell`, and a `devmode` switch.
- [technique] Interactive launcher commands use `$TERMINAL` with `kitty` fallback; long-running non-interactive commands pause for Enter so the terminal closes only after review.
- [fact] The `session` launcher group includes Lock, Log Out, Shut Down, Reboot, and Hibernate.

## Launcher Web Fallback Suppression

- [decision] Ambient web fallback rows are suppressed when any non-web backend produces visible rows for the same unprefixed query.
- [technique] Explicit web directives such as `@web`, `@g`, `@ddg`, `@gh`, and `@yt` still bypass suppression and show web rows directly.
- [fact] This keeps command groups like `session` and `newxos` from being crowded out by generic web search rows.

## Relations

- relates_to [[Launcher Web Fallback]]
- relates_to [[Launcher Newxos Actions]]

## Launcher Row Display Policy

- [decision] Launcher frontend row representation is driven by backend/node `behavior.displayPolicy`, not hard-coded delegate special cases.
- [technique] Breadcrumb arrays and breadcrumb notation are derived from the evaluated tree parent chain; display policy only decides whether that path is rendered.
- [fact] `Session` and `Newxos` action groups request `breadcrumbMode: "always"`; other action groups can opt in or use score-dependent modes such as `when-parent-dominates`.
- [requirement] Normalized rows must keep display policy as DTO data; executable backend payloads stay private to the backend.

## Relations

- relates_to [[Launcher Category Group Display]]
- relates_to [[Launcher Newxos Actions]]

## Launcher Row Icon Colors

- [fact] Launcher result rows can carry optional `iconColor` values through the composite row DTO.
- [technique] `DefaultResultDelegate.qml` and `TreeResultDelegate.qml` pass `result.iconColor` into the shared `Icon` component color overlay.
- [decision] Desktop action backends should use theme-derived `Config.styling` colors for semantic action icons instead of hard-coded hex values.
- [fact] Session action rows use colored icons for Lock, Log Out, Reboot, Shut Down, and Hibernate.

## Relations

- relates_to [[Launcher Row Display Policy]]
- relates_to [[Launcher Category Group Display]]

## Launcher Async Query Scheduling

- [decision] Launcher UI query updates are coalesced through `LauncherController.searchTimer` instead of running composite search directly inside `onTextEdited`.
- [technique] Each query update increments `generation`; queued searches and async backend callbacks check generation before applying results.
- [fact] `debugSearch`, `debugComplete`, and benchmarks still run synchronous composite search for deterministic IPC output.
- [technique] Process-backed launcher searches cancel the previous `Process` before starting a newer request.
- [requirement] Long synchronous JavaScript search work cannot be preempted mid-function by a newer keystroke; cancellation happens before queued work starts and when async callbacks return.

## Relations

- relates_to [[Launcher Composite Search]]
- relates_to [[Launcher File Queries]]

## Launcher Declarative Backend Trees

- [decision] Static launcher action trees can be authored as declarative QML `Node` and `Action` objects under one backend object.
- [technique] `TreeBackendBase` materializes declarative QML nodes into plain JS tree DTOs before composite search, keeping scoring/indexing on serializable data rather than live QML objects.
- [fact] `DesktopActionsBackend.qml` uses declarative nodes for the `Newxos` and `Session` groups while older object-tree helpers remain compatible for dynamic groups.
- [decision] Do not skip the DTO materialization step; live QML objects in the hot search path create circular refs, slower property access, and harder debug serialization.
- [technique] Base backend lifecycle signals (`searchStarted`, `searchFinished`, `searchCancelled`, `backendError`) provide the hook point for shared query/process management.

## Relations

- relates_to [[Launcher Backend Model Hierarchy]]
- relates_to [[Launcher Composite Search]]

## Launcher Backend DTO Factories

- [decision] `LauncherBackendBase.qml` centralizes launcher DTO creation with `actionDto`, `nodeDto`, and `backendRootDto` so individual backends do not import or hand-roll composite search nodes.
- [fact] Computed, streaming, process, tree, model-derived, desktop app, file, web, calculator, and help backends now route result construction through QML backend base factories.
- [technique] Declarative static actions use `Node.qml`/`Action.qml`; dynamic backends keep normal QML/JS bindings but emit the same plain JS DTO shape.
- [requirement] Keep `CompositeSearch*.js` as pure DTO processing; QML owns authoring, lifecycle, signals, and async/process cancellation.

## Relations

- relates_to [[Launcher Declarative Backend Trees]]
- relates_to [[Launcher Backend Model Hierarchy]]

## Launcher QML-First DTO Boundary

- [decision] Static launcher action namespaces in `DesktopActionsBackend.qml` are authored as declarative `Node { ... }` trees and materialized by `TreeBackendBase` into plain DTOs before search.
- [decision] Dynamic QML-owned child lists, such as dashboard tabs and VPN destinations, attach to a QML `Node` through `dynamicChildren`; they remain plain tree objects rather than live child QML objects when generated from data.
- [decision] External/process backends should not round-trip process rows through live QML `Node` objects; QML owns process lifecycle and normalization, then emits DTOs through backend factories.
- [technique] Switch rows require an explicit `switchState`; parent groups with switch children should not be inferred as switches.

## Relations

- relates_to [[QuickShell desktop shell requirements]]
- relates_to [[Encountered Issues]]

## Launcher Template Nodes

- [decision] Static launcher action trees use QML template nodes for repeated defaults: `ActionNode`, `ActionGroupNode`, `FlatActionGroupNode`, `SwitchNode`, and `SwitchActionNode`.
- [technique] `Node.qml` carries `template` and `groupOptions` metadata; `TreeBackendBase.qml` expands group templates into centralized category group behavior before DTO search.
- [fact] `DesktopActionsBackend.qml` no longer calls `categoryGroupBehavior(...)` directly for static desktop action groups; group defaults can be changed through the template/base components.
- [technique] `SwitchActionNode` centralizes default on/off/toggle names, titles, icons, state payloads, and dangerous-off behavior while preserving per-action executors.

## Relations

- relates_to [[Launcher Declarative Backend Trees]]
- relates_to [[Launcher QML-First DTO Boundary]]

## Launcher Category Group Flattening

- [decision] `ActionGroupNode` defaults to flattening matching categories into actionable child rows so groups do not render as non-executable blank tree rows.
- [technique] `CompositeSearchFlatten.flattenActionableChildren()` walks through non-action wrapper groups and emits executable leaves or switch rows, which keeps nested groups such as `Power > Power Mode > Performance` visible and actionable.
- [requirement] Use nested tree group display only when the parent row is intentionally useful; command namespaces should prefer actionable flattened rows.

## Relations

- relates_to [[Launcher Template Nodes]]
- relates_to [[Launcher Category Group Display]]
