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

- [decision] Launcher search now uses a prototype-derived composite node pipeline in `configs/quickshell/launcher/logic/CompositeSearch.js` instead of the older `CommandTree`/`EvidenceScorer` ranking path.
- [fact] Launcher backends expose `rootNode(query, context)` trees that the controller evaluates, scores with evidence, and flattens for UI rows.
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
