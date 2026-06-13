# QuickShell Motion Playbook

Use this when adding hover, press, expand/collapse, tab, panel, or row animations.

## Core Rule

Motion must preserve the flat design contract. Animate state, not decoration.

## Motion Tokens

All animation durations must use central tokens from `Config.behaviour.animation`:

| Token | Value | Use |
|-------|-------|-----|
| `micro` | 100ms | hover, press, background color state layer |
| `short` | 160ms | button expansion, label reveal, row selection |
| `medium` | 220ms | panel/tab transitions, reveal/collapse |
| `long` | 320ms | large layout changes |

Access via `Config.behaviour.animation.micro` / `.short` / `.medium` / `.long` or the convenience alias `Config.motion.micro` / `.short` / `.medium` / `.long`.

## Animation Module

Use the dedicated animation module for shell animation work:

```qml
import qs.animations as Animations
```

Prefer animation recipes over local `Behavior { NumberAnimation {} }` blocks:

```qml
Animations.RevealBehavior on opacity {
}

Animations.StateColorBehavior on color {
}
```

Use `Animations.FadeInAnimation` and `Animations.FadeOutAnimation` inside explicit sequences:

```qml
SequentialAnimation {
    Animations.FadeOutAnimation {
        target: label
        property: "opacity"
        to: 0
    }
}
```

## Foundations

Foundations are narrow, configurable animation building blocks. Use them when no named recipe fits.

| Component | Use |
|-----------|-----|
| `Animations.NumberBehavior` | attach to numeric properties with configurable `kind`, `duration`, `easingType` |
| `Animations.ColorBehavior` | attach to color properties with configurable `kind`, `duration`, `easingType` |
| `Animations.PropertyAnimation` | explicit numeric animation for `SequentialAnimation` / `ParallelAnimation` |

Available number kinds:

| Kind | Duration | Easing | Use |
|--------|----------|--------|-----|
| `Micro` | `Config.motion.micro` | `Easing.OutCubic` | tiny state changes |
| `Short` | `Config.motion.short` | `Easing.OutCubic` | button expansion, label movement |
| `Medium` | `Config.motion.medium` | `Easing.OutCubic` | panel/tab transitions |
| `Long` | `Config.motion.long` | `Easing.OutCubic` | large layout changes |
| `Enter` | `Config.motion.short` | `Easing.OutCubic` | reveal/hover-in |
| `Exit` | `Config.motion.short` | `Easing.InCubic` | hide/collapse |
| `Layout` | `Config.motion.medium` | `Easing.InOutCubic` | size/layout interpolation |
| `Neutral` | `Config.motion.short` | `Easing.InOutQuad` | neutral state changes |

Available color kinds:

| Kind | Duration | Easing | Use |
|--------|----------|--------|-----|
| `State` | `Config.motion.micro` | `Easing.OutCubic` | hover/active color changes |
| `Neutral` | `Config.motion.short` | `Easing.InOutQuad` | slower neutral color changes |
| `Accent` | `Config.motion.micro` | `Easing.OutCubic` | accent swaps |

## Recipes

Recipes are finished animation choices composed from foundations. Prefer these for consistency.

| Component | Based on | Use |
|-----------|----------|-----|
| `Animations.StateColorBehavior` | `ColorBehavior(State)` | hover, active, accent color transitions |
| `Animations.RevealBehavior` | `NumberBehavior(Enter)` | opacity reveal or content fade-in |
| `Animations.ShiftBehavior` | `NumberBehavior(Short)` | small x/y/position transitions |
| `Animations.ExpandBehavior` | `NumberBehavior(Short)` | button width/height expansion |
| `Animations.PanelBehavior` | `NumberBehavior(Medium)` | dashboard/panel open, width, opacity |
| `Animations.LayoutBehavior` | `NumberBehavior(Layout)` | size/layout interpolation |
| `Animations.ScaleBehavior` | `NumberBehavior(Micro)` | restrained hover/press scale feedback |
| `Animations.FadeInAnimation` | `PropertyAnimation(Enter)` | explicit fade-in in sequences |
| `Animations.FadeOutAnimation` | `PropertyAnimation(Exit)` | explicit fade-out in sequences |
| `Animations.AppearAnimation` | `FadeInAnimation` + `MotionAnimation(Layout)` | top-anchored list/delegate insertion by expanding wrapper height and fading in |
| `Animations.DisappearAnimation` | `MotionAnimation(Layout)` | top-anchored list/delegate removal by shrinking wrapper height to zero |
| `Animations.RetainedDisappearAnimation` | `ListView.delayRemove` + height shrink | keep a removed `ListView` delegate alive until its height reaches zero |
| `Animations.SpinAnimation` | `RotationAnimation` | sustained loading/connecting spinner |
| `Animations.SettledShiftBehavior` | `ShiftBehavior` with delayed enable | state that must snap on creation, then animate later |
| `Animations.SettledStateColorBehavior` | `StateColorBehavior` with delayed enable | color state that must snap on creation, then animate later |

Each foundation and recipe exposes override properties (`duration` / `easingType` for behaviors, `motionDuration` / `motionEasingType` for explicit animations) for component-specific cases.

Use settled recipes for controls whose initial state comes from live data. Example: a Wi-Fi switch created while Wi-Fi is already enabled must appear on immediately; only later state changes should animate.

Use `Animations.ScaleBehavior` only for restrained feedback. Preferred ranges are `0.92 -> 1.0`, `0.96 -> 1.0`, or at most `1.0 -> 1.02`.

## Preferred Easing

| Context | Easing |
|---------|--------|
| enter / expand / hover-in | `Easing.OutCubic` |
| exit / collapse | `Easing.InCubic` |
| size / layout transitions | `Easing.InOutCubic` |
| neutral state changes | `Easing.InOutQuad` |

## Allowed Motion

- opacity changes
- color interpolation between flat palette tokens
- width/height interpolation
- background expansion/reveal
- small content slide/fade
- restrained scale (already established patterns only)

## Forbidden Motion

- drop shadows, glow effects, gradients
- fake depth/elevation
- springy/bouncy motion (spring animations)
- large scale jumps (>1.05)
- blur-heavy transitions
- animations that cause search-result jitter

## Reduced/Disabled Animation

All animations must respect `Config.behaviour.animation.enabled`. The motion tokens already handle this — `micro`, `short`, `medium`, `long` return 0 when animations are disabled.

Do not hardcode nonzero durations without checking the enabled flag:

```qml
duration: Config.behaviour.animation.enabled ? someDuration : 0
```

Prefer using animation recipes or motion tokens which are pre-guarded.

## Expanding Buttons

Expanding buttons reveal a label alongside an icon on hover or active state. Key rules:

- Icon position must remain stable during expansion.
- Label fades in (opacity) while button expands (width).
- Background color transitions between flat tokens.
- Active state uses `primaryAccent` for icon/label color.
- Expansion direction respects layout context (right-side clusters expand inward).

Reference implementation: `configs/quickshell/components/ExpandableButton.qml`.

## Dashboard-Bar Integration

Bar status icons remain icon-only. The right-side cluster expansion is owned by `ShellState.barExpandedForDashboard` and `Bar.qml`; `StatusIcon.qml` keeps icon, badge, overlay, hover, and active feedback only.

Do not duplicate dashboard open/close/tab state in animated button components. Buttons delegate to `screenState.toggleDashboard(tab)`.

## Dashboard Expanders

Use `configs/quickshell/components/Expander.qml` for clipped expand/collapse reveals. It owns the standard settled initial state, height progress, content-height changes, and slide-down/up motion so content appears to come from the parent.

Use `DashboardSection { collapsible: true }` for dashboard sections such as NordVPN/VPN. It delegates body reveal to `Expander`.

For row-level expanders such as Wi-Fi and Bluetooth device details, keep the expansion state local to the page and wrap details in `Expander`. Do not reorder live rows while a row is expanded; freeze row order if needed.

## Launcher Frontend Motion

Launcher motion is UI-only. Do not change matching, evidence, scoring, ranking, row shaping, backend participation, or policy logic.

Safe launcher targets:

- top-level result `ListView` add/remove/displaced transitions
- selected row background and border color
- breadcrumb opacity
- action hint opacity
- top-level tree reveal height/slide through `Expander`
- tree row panel height/color/border
- tree row entry opacity for visible child rows
- switch controls through `DashboardToggleSwitch`

`TreeView` inherits `TableView`, not `ListView`; do not add unsupported `add`/`remove`/`displaced` transitions to it. Animate tree expand/collapse through the containing clipped wrapper and row delegates instead.

When launcher results spawn already expanded, the initial tree state must snap into place. Enable tree reveal, row-height, and child-entry animations only after the initial model/default expansion layout settles, so motion only communicates later state changes.

Tree parents stay visually stationary. Do not stretch a parent row background over its descendants; collapse and reveal only the child area below it.

For tree expand/collapse, animate all affected heights. Use `Expander` for the outer launcher tree reveal and `AnimatedListDelegate` for the parent `ListView` row height. For nested `TreeView` branches, use `TreeView.rowHeightProvider` for child row growth/shrink and delay the real `TreeView.collapse()` until the shrink finishes; otherwise Qt removes child rows immediately while the parent area is still animating. Pair the height animation with a small upward-to-settled `y` offset so children slide down/up as if produced by the parent.

For `ListView` delegate add/remove, wrap composed rows in `components/AnimatedListDelegate.qml`. Fade-only removal leaves invisible rows occupying space while the outer frame shrinks.

If a `ListView` is backed by snapshot arrays that reset on every query, pass a stable `animationKey` and shared `seenKeys` object to `AnimatedListDelegate`; otherwise unchanged rows replay their add animation on every snapshot.

When `ListView` removals need exit animation, use `ListView.delayRemove` through `Animations.RetainedDisappearAnimation` so Qt keeps the delegate alive until its clipped wrapper height animates to zero. Do not fade removed list rows unless the design specifically calls for it; height-only removal matches the containing background resize.

Avoid adding a second behavior to nested `TreeView` row heights when child row heights already drive the reveal. Double-animating parent and child heights makes collapse look sequential instead of simultaneous.

## Validation

Check these states for any animated component:

1. Compact/default state.
2. Hovered.
3. Pressed.
4. Active/selected.
5. Expanded (if applicable).
6. With animations disabled (`duration_multiplier = 0`).

## Do Not

- Hardcode animation durations outside motion tokens or animation recipes.
- Add shadows, gradients, glows, or elevation in animation targets.
- Hardcode colors outside theme/config tokens.
- Animate every component in one pass — migrate incrementally.
- Introduce a generic animation framework larger than current needs.
- Break hot reload with persistent animation state.
- Add external dependencies for motion.
