# QuickShell design contracts

## Visual style — flat design

- No gradients, drop shadows, or 3D effects.
- Solid color fills for backgrounds and panels.
- Visual hierarchy from color contrast and spacing, not depth cues.
- Borders only when necessary; prefer background color shifts.

## Spacing grid

All spacing, padding, and margins use a consistent scale:

- 4px: tightly related elements (icon+label, list row items)
- 8px: related elements within same component (form fields, tabs, widgets)
- 12px: distinct sections sharing context (widget groups, header gaps)
- 16px: top-level layout boundaries, section separators

Keep spacing consistent within a component. Read `Config.spacing` for exact values.

## Color palette

- All colors come from the Catppuccin/Stlix pipeline (`modules/theming/`).
- Follow Catppuccin semantic roles: `blue` for primary, `green` for active, `red` for errors, `yellow` for warnings.
- Background layers: `base`, `mantle`, `crust` progression for depth without gradients.
- Text: `text` primary, `subtext0`/`subtext1` for secondary.
- One primary accent (`blue`) and one secondary (`sky`) per view max.
- Do not introduce colors outside the palette. Derive new shades with `colorWithOpacity()`.

## Animations

- Only for state transitions (hover, focus, toggle, open/close), not decoration.
- 100-250ms for micro-interactions, up to 400ms for panel open/close.
- Prefer `Easing.InOutQuad` or `Easing.OutCubic`.
- Respect `behaviourObj.animation.enabled`; skip animations when disabled.
- Use `behaviourObj.animation.calc(baseSeconds)` for duration calculation.

## Layout

- Flat panels with consistent padding.
- No rounded corners by default (`styleState.rounded` controls this; keep `false` unless needed).
- Prefer `Column`/`Row` with `spacing` over nested anchors for simple layouts.
- Maintain consistent margins across panels and widgets.

## QML conventions

- Required pragmas: `pragma Singleton`, `pragma ComponentBehavior: Bound`.
- Files: PascalCase matching component name.
- Singletons: PascalCase accessed directly by name.
- Root id: always `id: root`.
- Inline components: `component Name: BaseType {}`.
- Imports: use `qs.` prefix for local modules.
- Type annotations on function parameters and signal arguments.
- Null safety with optional chaining (`sink?.audio?.volume ?? 0`).

## Service architecture

- Services are `pragma Singleton` with `Singleton {}` root.
- Use `IpcHandler` for CLI access, `CustomShortcut` for keyboard shortcuts.
- `PersistentProperties` for hot-reload safe state (must have unique `reloadableId`).
- Communication: Hyprland socket IPC, PipeWire audio, D-Bus notifications, `Process` for subprocess, `FileView` for file watching.
- State survives hot reload through `PersistentProperties`.

## Module patterns

- **Wrapper/Content/Background triad** for panels: a wrapper manages visibility state/transitions, content holds UI, background holds the shape.
- **Per-screen instantiation** via `Variants { model: Quickshell.screens }`.
- **Lazy loading** via conditional `Loader` activation or timer-delayed initialization.
- **State/transition pattern** for panels: `Item` with `implicitHeight: 0`, `states` for visible, `transitions` for animation.

## Anti-patterns to avoid

- Do not hardcode colors or sizes — use `Colours.palette.*` and `Appearance.*`.
- Do not create multiple `FileView` for the same file — centralize in a service.
- Do not poll when not needed — use `refCount > 0` guards.
- Do not forget `reloadableId` on `PersistentProperties` — state lost on reload.
- Do not put raw backend/evaluation objects into ListView models or IPC responses.
- Do not prewarm async backends before their source model is populated.
- Normalized launcher rows must not carry raw tree objects.
