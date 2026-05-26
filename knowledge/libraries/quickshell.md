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
