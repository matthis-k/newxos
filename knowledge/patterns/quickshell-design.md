---
id: quickshell-design
type: reference
title: QuickShell design guidelines
status: active
tags:
- quickshell
- theming
- catppuccin
- nix
links:
- libraries-stylix
- libraries-quickshell
updated: 2026-05-12
permalink: newxos/quickshell-design
---

# QuickShell design guidelines

## Observations

- [decision] QuickShell UI must follow flat design principles: no gradients, drop shadows, or 3D effects
- [fact] Use a small spacing grid for all spacing, padding, and margins; read `Config.spacing` for exact values
- [fact] Colors come from the repo Catppuccin/Stylix pipeline; read `modules/theming/` and `configs/quickshell/services/Config.qml` for exact keys
- [decision] Animations should be responsive and subtle, not decorative: 100-250ms for micro-interactions, up to 400ms for panel open/close

## Relations

- relates_to [[libraries-stylix]]
- relates_to [[libraries-quickshell]]

## Visual style

QuickShell UI must follow **flat design** principles:

- No gradients, drop shadows, or 3D effects.
- Solid color fills for backgrounds, panels, and interactive elements.
- Rely on color contrast and spacing for visual hierarchy, not depth cues.
- Borders only when necessary for separation; prefer background color shifts.

### Classic flat design reference

Follow the "Flat Design" movement as established in the early 2010s -- clean, minimal interfaces that strip away skeuomorphic decoration:

- **Typography as hierarchy**: font weight and size carry structure, not visual depth.
- **Iconography**: simple, geometric, two-tone at most. No bevels, embossing, or inner shadows.
- **Color blocks**: large solid color areas define sections instead of containers with borders.
- **Content-first**: remove chrome; let the content be the interface.

See the original flat design principles for reference:
- Microsoft Metro/Modern UI (Windows Phone 7, Windows 8)
- iOS 7 redesign (Jony Ive, 2013)
- Google Material Design (flat base with intentional elevation for interaction states only)

## Spacing

Use a small base grid for all spacing, padding, and margins. Exact spacing constants live in `configs/quickshell/services/Config.qml`.

### Spacing coherence rules

- **Tighter spacing** (4-8px): elements that belong together -- icon + label, items in a list row, button icon + text.
- **Medium spacing** (12-16px): related elements within the same component -- form fields in a group, tabs in a bar, widgets in a panel.
- **Larger spacing** (24-32px): distinct sections that share context -- separate widget groups in a panel, header-to-content gaps.
- **Maximum spacing** (48-64px): unrelated content blocks, top-level layout boundaries.

Keep spacing consistent within a component. If a bar uses 8px internal padding, all widgets in that bar should use 8px as their base unit.

## Color palette

All colors come from the Catppuccin/Stylix palette pipeline.

Read `modules/theming/` for generated palette files and `configs/quickshell/services/Config.qml` for the current runtime API.

### Color choice rules

- Follow Catppuccin's intended semantic roles: `blue` for primary actions, `green` for success/active, `red` for errors/close, `yellow` for warnings, `peach` for urgent.
- Background layers use the surface-to-crust progression (`base`, `mantle`, `crust`) for depth without gradients.
- Text uses `text` for primary, `subtext0`/`subtext1` for secondary/deemphasized content.
- Accent colors from the palette should be used sparingly -- one primary accent (`blue`) and one secondary (`sky`) per view.
- Do not introduce colors outside the palette. If a new shade is needed, derive it from existing palette colors using `colorWithOpacity()`.

## Animations

Animations should be **responsive and subtle**, not decorative:

- Use animations only for state transitions that communicate feedback (hover, focus, toggle, open/close).
- Keep durations short: 100-250ms for micro-interactions, up to 400ms for panel open/close.
- Prefer `Easing.InOutQuad` or `Easing.OutCubic` for natural motion.
- Respect the `behaviourObj.animation.enabled` flag -- if disabled, skip animations entirely.
- Use `behaviourObj.animation.calc(baseSeconds)` for duration calculation so the multiplier applies globally.

### Dashboard Motion

- Put tab-switch animation in a shared container such as `SwipeView` so every dashboard-like surface gets the same slide/fade behavior.
- Put resize animation in shared shells such as `DashboardSection` so split panes and expanding sections animate without each tab re-implementing height transitions.
- Keep the top bar and dashboard on the same timing/easing when the right-side indicator strip expands into tab selectors.
- For expandable rows inside tabs, animate the row height and details opacity together instead of only toggling `visible`.

## Layout

- Use flat panels with consistent padding and spacing (see Spacing section above).
- No rounded corners by default (`styleState.rounded` controls this; keep `false` unless explicitly needed).
- Maintain consistent margins across panels and widgets.
- Prefer `Column`/`Row` with `spacing` over nested anchors for simple layouts.
- Keep `Dashboard*` components responsible for spacing, text presets, backgrounds, and accessory slots; page files should mostly compose content into those shells.
- Prefer small generic primitives such as `DashboardHeader`, `DashboardToggleSwitch`, and controls-based sliders over content-specific one-off components.
- Put page-global actions or toggles in page header accessory slots, and section-local actions in section header accessory slots, instead of adding extra control rows beneath the header.

## Related

- [[libraries-stylix]] -- palette source and theme generation
- [[libraries-quickshell]] -- QuickShell toolkit reference
