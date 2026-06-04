---
name: quickshell-qml-component
description: Use when editing QuickShell QML components, panels, services, layout, theming, animations, hot reload behavior, or related wrapper config in newxos.
---

# QuickShell QML Component Work

Use this skill for `configs/quickshell/` changes that are not specifically launcher search pipeline changes.

## Inspect First

- Read `docs/contracts/quickshell-design.md`.
- For live config iteration, read `docs/playbooks/dev-specialization.md`.
- For wrapper behavior, inspect `modules/desktop/wrappers/quickshell.nix`.
- For known Quickshell pitfalls, read `docs/pitfalls.md`.
- Inspect nearby QML components and services before adding patterns.

## Design Rules

- Flat design only: no gradients, drop shadows, or 3D effects.
- Use palette/theme values such as `Colours.palette.*` and `Appearance.*`; do not hardcode colors or sizes.
- Follow the repo spacing scale: 4, 8, 12, 16 px roles from the contract.
- Use color contrast and spacing for hierarchy, not depth effects.
- Respect animation settings and keep animation tied to state transitions.

## QML Rules

- Use `id: root` for component roots.
- Use repo import conventions and nearby component patterns.
- Services should be `pragma Singleton` with `Singleton {}` root.
- `PersistentProperties` must have a unique `reloadableId`.
- Centralize repeated file watches or polling in services.
- Avoid polling unless a visible/ref-counted consumer needs the data.

## Procedure

1. Classify the change as component, service, panel, theme, or wrapper interaction.
2. Preserve existing visual language and module structure.
3. Make the smallest QML/source change.
4. Check hot reload assumptions when state or wrapper paths change.
5. Run the relevant QuickShell/QML checks or explain why they were skipped.

## Do Not

- Put raw launcher backend/evaluation objects into UI models.
- Duplicate wrapper-generated config in handwritten QML.
- Treat generic upstream QuickShell snippets as repo policy.
