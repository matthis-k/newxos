---
id: issue-prefers-color-scheme-dark
type: issue
title: prefers-color-scheme-dark not respected
status: active
tags:
- issue
- theming
- gtk
links:
- issues-index
- theming-gtk
- theming-stylix
updated: 2026-05-11
permalink: newxos/issues/prefers-color-scheme-dark
---

# prefers-color-scheme-dark not respected

## Problem

Some applications do not respect the `prefers-color-scheme: dark` media query.

## Symptoms

- GTK apps may use light theme when dark theme is expected.
- Web apps may not switch theme automatically.

## Cause

Theme propagation to `prefers-color-scheme` depends on portal config, GTK settings, and Stylix target support.

## Related

- [[theming-gtk]]
- [[theming-stylix]]