---
name: quickshell-qml-component
description: Use when editing QuickShell QML components, panels, services, layout, theming, animations, hot reload behavior, or related wrapper config in newxos.
---

# QuickShell QML Component

## Core Rule

All UI must follow the flat-design contract: no gradients, shadows, or 3D. Use palette tokens and the repo spacing scale. Never hardcode colors or sizes.

## Inspect First

- `docs/contracts/quickshell-design.md` — visual style, spacing scale, animation rules, QML conventions
- `docs/pitfalls.md` — Quickshell section
- `docs/playbooks/dashboard-change.md` — dashboard/quickmenu tab state, ShellState ownership, tab order, and validation
- `modules/desktop/wrappers/quickshell.nix` — wrapper, newshell binary, dev mode routing
- Nearby QML components for import conventions and pattern matching

## Ownership Map

| Path | Owns |
|------|------|
| `configs/quickshell/shell.qml` | Root window, panel layout, per-screen instantiation |
| `configs/quickshell/services/` | Singleton services (network, brightness, config, notifications) |
| `configs/quickshell/components/` | Shared UI components (buttons, sliders, icons, dashboard pieces) |
| `configs/quickshell/modules/*/` | Panel modules (quickmenu, background, hyprland preview) |
| `configs/quickshell/launcher/` | Launcher search pipeline (see launcher-search-change skill) |
| `modules/desktop/wrappers/quickshell.nix` | Wrapper, newshell binary, dev mode config routing |
| `modules/theming/` | Palette, generated QuickShell theme JSON |

## Change Routing

| Symptom | Edit |
|---------|------|
| Color or spacing wrong | Check `docs/contracts/quickshell-design.md`, then theme tokens |
| Component pattern missing | Match nearest existing component in `components/` |
| Service state lost on reload | Add unique `reloadableId` to `PersistentProperties` |
| Panel behavior change | Edit owning module file in `modules/<panel>/` |
| Hot reload not working | Check dev mode wrapper logic; verify `NEWXOS_DEV=1` |
| New service needed | Add `pragma Singleton` file in `services/` |
| File watch duplicated | Centralize in service, not multiple components |
| Dashboard state/tab behavior wrong | Read `docs/playbooks/dashboard-change.md`; keep state in `ShellState.qml` |

## Design Rules

- Flat design: no gradients, shadows, 3D effects.
- Colors: `Colours.palette.*` and `Appearance.*`.
- Spacing: 4/8/12/16 px scale from `Config.spacing`.
- Animations: state transitions only, 100-400ms, `Easing.InOutQuad` or `Easing.OutCubic`.
- Respect `behaviourObj.animation.enabled`; skip animations when disabled.
- One primary accent (`blue`) and one secondary (`sky`) per view max.

## QML Rules

- `id: root` for component roots.
- `pragma Singleton` + `Singleton {}` root for services.
- `PersistentProperties` must have unique `reloadableId`.
- Centralize repeated file watches or polling in services.
- No polling without `refCount > 0` guard.
- Use repo import conventions (`qs.` prefix for local modules).
- PascalCase filenames matching component name.

## Procedure

1. Classify change: component, service, panel, theme, or wrapper interaction.
2. Match existing conventions and patterns.
3. Make the smallest QML/source change.
4. Check hot reload assumptions if state or wrapper paths changed.
5. Verify with dev specialization or repo-gate.

## Validation

- `nix run "path:$PWD#repo-gate"` for handoff.
- In dev mode: restart `newshell` session to hot-reload.
- For hot-reload state: verify with `newshell ipc` queries.

## Do Not

- Hardcode colors or sizes.
- Put raw backend objects into UI models or IPC responses.
- Duplicate wrapper-generated config in handwritten QML.
- Treat generic QuickShell snippets as repo policy.
- Prewarm async backends before source model is populated.
- Duplicate dashboard open/close/tab state outside `ShellState.qml`.

## Done Criteria

- Design contract respected (no gradients, shadows, 3D).
- No hardcoded theme values.
- Hot reload state preserved if relevant.
- Formatting applied.
