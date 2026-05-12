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

Use a **4px base grid** for all spacing, padding, and margins. Values scale in multiples of 4:

| Scale | Value | Use case |
|-------|-------|----------|
| `4` | 4px | Tight inline gaps (icon-to-text, small element padding) |
| `8` | 8px | Default padding, related item spacing |
| `12` | 12px | Medium gaps within a component |
| `16` | 16px | Standard section padding, card inner spacing |
| `24` | 24px | Large gaps between related sections |
| `32` | 32px | Major section breaks, panel margins |
| `48` | 48px | Page-level spacing, between unrelated groups |
| `64` | 64px | Maximum gap, layout boundaries |

### Spacing coherence rules

- **Tighter spacing** (4-8px): elements that belong together -- icon + label, items in a list row, button icon + text.
- **Medium spacing** (12-16px): related elements within the same component -- form fields in a group, tabs in a bar, widgets in a panel.
- **Larger spacing** (24-32px): distinct sections that share context -- separate widget groups in a panel, header-to-content gaps.
- **Maximum spacing** (48-64px): unrelated content blocks, top-level layout boundaries.

Keep spacing consistent within a component. If a bar uses 8px internal padding, all widgets in that bar should use 8px as their base unit.

### QML pattern

All spacing constants live in `Config.spacing`. Access them directly:

```qml
Row {
    spacing: Config.spacing.xs  // 8px for related items
    // ...
}

Column {
    spacing: Config.spacing.md  // 16px for sections
    // ...
}
```

Available properties:

| Property | Value | Scale name |
|----------|-------|------------|
| `Config.spacing.xxs` | 4px | tight inline |
| `Config.spacing.xs` | 8px | default padding |
| `Config.spacing.sm` | 12px | medium component gap |
| `Config.spacing.md` | 16px | standard section |
| `Config.spacing.lg` | 24px | large section break |
| `Config.spacing.xl` | 32px | panel margin |
| `Config.spacing.xxl` | 48px | page-level gap |
| `Config.spacing.xxxl` | 64px | layout boundary |

## Color palette

All colors come from the Catppuccin palette passed through a JSON file in the Nix store.

### How it works

1. `modules/stylix/quickshell.nix` generates `catppuccin-palette.json` from `config.stylix.fullPalette.colors` and installs it to `$XDG_CONFIG_HOME/quickshell/`.
2. `configs/quickshell/services/Config.qml` reads the JSON at runtime via `FileView` + `JsonAdapter`.
3. The 24 semantic Catppuccin colors are exposed through `Config.colors` and `Config.styling` / `Config.palette`.

### Palette keys

The JSON provides all 24 Catppuccin Mocha semantic colors:

| Category | Keys |
|----------|------|
| Accents | `rosewater`, `flamingo`, `pink`, `mauve`, `red`, `maroon`, `peach`, `yellow`, `green`, `teal`, `sky`, `sapphire`, `blue`, `lavender` |
| Text | `text`, `subtext1`, `subtext0` |
| Overlays | `overlay2`, `overlay1`, `overlay0` |
| Surfaces | `surface2`, `surface1`, `surface0`, `base`, `mantle`, `crust` |

### Color choice rules

- Follow Catppuccin's intended semantic roles: `blue` for primary actions, `green` for success/active, `red` for errors/close, `yellow` for warnings, `peach` for urgent.
- Background layers use the surface-to-crust progression (`base`, `mantle`, `crust`) for depth without gradients.
- Text uses `text` for primary, `subtext0`/`subtext1` for secondary/deemphasized content.
- Accent colors from the palette should be used sparingly -- one primary accent (`blue`) and one secondary (`sky`) per view.
- Do not introduce colors outside the palette. If a new shade is needed, derive it from existing palette colors using `colorWithOpacity()`.

### Accessing colors in QML

```qml
// From Config.colors (raw Catppuccin names)
color: Config.colors.blue
color: Config.colors.crust

// From Config.styling (semantic aliases)
color: Config.styling.bg0
color: Config.styling.primaryAccent
color: Config.styling.good
```

## Animations

Animations should be **responsive and subtle**, not decorative:

- Use animations only for state transitions that communicate feedback (hover, focus, toggle, open/close).
- Keep durations short: 100-250ms for micro-interactions, up to 400ms for panel open/close.
- Prefer `Easing.InOutQuad` or `Easing.OutCubic` for natural motion.
- Respect the `behaviourObj.animation.enabled` flag -- if disabled, skip animations entirely.
- Use `behaviourObj.animation.calc(baseSeconds)` for duration calculation so the multiplier applies globally.

### Example

```qml
Behavior on opacity {
    NumberAnimation {
        duration: behaviourObj.animation.enabled
            ? behaviourObj.animation.calc(0.15)
            : 0
        easing.type: Easing.OutCubic
    }
}
```

## Layout

- Use flat panels with consistent padding and spacing (see Spacing section above).
- No rounded corners by default (`styleState.rounded` controls this; keep `false` unless explicitly needed).
- Maintain consistent margins across panels and widgets.
- Prefer `Column`/`Row` with `spacing` over nested anchors for simple layouts.

## Related

- [[libraries-stylix]] -- palette source and theme generation
- [[libraries-quickshell]] -- QuickShell toolkit reference
