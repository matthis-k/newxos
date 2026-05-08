# quickshell

Quickshell provides a QtQuick-based shell toolkit, and this repo exposes a tiny `newshell` wrapper for the repo-owned template config.

## What It Does Here

- Keeps the hand-written template config in `configs/quickshell/`.
- Exposes `newshell`, which forwards to `quickshell -p <repo-template-dir>`.
- Installs both the raw `quickshell` binary and the repo wrapper through Home Manager so ad hoc runs stay available.
- Sets `QS_ICON_THEME` from the active Stylix icon selection so `quickshell` and `newshell` stay aligned.
- Keeps the wrapper minimal instead of copying Quickshell config into `~/.config/`.

## Basics

- Edit `configs/quickshell/shell.qml` when changing the repo template.
- Use `newshell` for the repo template and `quickshell` directly for other config paths.
- Leave `.qmlls.ini` untracked next to `shell.qml`; Quickshell manages it per machine for `qmlls` support.
- Related reading: [Wrapped Programs And Generated Config](../patterns/wrapped-programs.md), [Flake Structure](../flake-structure.md#configs).

## Helpful Docs

- Install and setup guide: `https://quickshell.org/docs/v0.3.0/guide/install-setup/`
- Guide index: `https://quickshell.org/docs/v0.3.0/guide`
- Upstream mirror: `https://github.com/quickshell-mirror/quickshell`

## Known Quirks Here

- The wrapper's config path is fixed at build time, so config edits take effect after the package is rebuilt through the normal Home Manager or flake flow.
- Keep the template lightweight unless the repo starts managing a fuller shell layout.
