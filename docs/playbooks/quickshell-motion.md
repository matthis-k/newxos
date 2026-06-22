# QuickShell Motion Playbook

Use this when adding hover, press, expand/collapse, tab, panel, or row animations.

## Core Rule

Motion must preserve the flat design contract. Animate state, not decoration.

## Motion policy

- Use the shared animation module (`import qs.animations as Animations`). Prefer named recipes over local `Behavior { NumberAnimation {} }` blocks.
- All durations come from `Config.behaviour.animation.*` or `Config.motion.*` — never hardcode duration literals.
- Respect `Config.behaviour.animation.enabled`. Motion tokens return 0 when disabled.
- Preferred easing: `Easing.OutCubic` for enter/expand, `Easing.InCubic` for exit/collapse, `Easing.InOutCubic` for layout, `Easing.InOutQuad` for neutral.
- Settled recipes for components whose initial state comes from live data (e.g. Wi-Fi switch already on).

## Allowed motion

- opacity changes, color interpolation between flat palette tokens, width/height interpolation
- background expansion/reveal, small content slide/fade
- restrained scale (0.92-1.0 or 0.96-1.0 range only)

## Forbidden motion

- drop shadows, glow, gradients, fake depth/elevation
- springy/bouncy motion, large scale jumps (>1.05), blur-heavy transitions
- animations that cause search-result jitter

## Key component patterns

- **Expander** (`components/Expander.qml`): clipped reveal/collapse for sections and expanders
- **AnimatedListDelegate** (`components/AnimatedListDelegate.qml`): list row add/remove height animation
- **TransitionListCoordinator** + **AnimatedTransitionList** (`animations/`): snapshot-driven lists with stable keys, reorder, fast-input adaptation

## Launcher motion

Launcher motion is visual-only. Do not change matching, evidence, scoring, ranking, row shaping, backend participation, or policy logic.

Safe targets: top-level list add/remove/displaced, selected row color, breadcrumb/action hint opacity, tree reveal height via Expander, tree row panel height/color/border.

## Expanding buttons

Icon position stable during expansion; label fades in while button expands; background transitions between flat tokens. Source: `components/ExpandableButton.qml`.

## Validation

Check each animated component at: compact state, hovered, pressed, active/selected, expanded, animations disabled, fast input (for snapshot-driven lists).

## Do Not

- Hardcode animation durations outside motion tokens or animation recipes.
- Add shadows, gradients, glows, or elevation.
- Animate every component in one pass — migrate incrementally.
- Break hot reload with persistent animation state.
- Add external dependencies for motion.
