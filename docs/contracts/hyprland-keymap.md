# Hyprland keymap resolver

Source owners:
- DSL/config: `configs/hypr/keybinds.lua`
- Resolver modules: `configs/hypr/keymap/`
- Synthetic tests: `configs/hypr/keymap/tests.lua`

## Contract

Hyprland keybinds are declared through `keymap.map({ keys = ..., binds = ... })`. The normalized config and pure resolver are the source of truth; backend adapters may only compile or feed events into that resolver.

Rules model physical key press/release cycles, not hard-coded modifier behavior. A cycle may be free, participated, reserved, or fully consumed. Held chord participants default to participated, so their taps are blocked while the key remains chainable for later chords. Trigger keys default to full consumption for simple press binds and reservation for tap/hold/long/release rules.

Normal binds stay concise:

```lua
{
    chord = { held = { "super" }, trigger = "return" },
    action = actions.terminal,
    description = "Terminal",
}
```

Standalone tap/hold behavior is key-level config:

```lua
keys = {
    super = {
        tap = actions.launcher,
        description = "Launcher",
    },
}
```

Dual trigger behavior is rule-level config:

```lua
{
    chord = { held = { "super" }, trigger = "h" },
    actions = {
        tap = actions.focus_left,
        hold = actions.move_window_left,
        repeat_ = actions.move_window_left,
    },
    repeat = { phase = "hold" },
}
```

## Backend Limits

The pure resolver supports arbitrary `on_key_down`, `on_key_up`, and timer events. Current Hyprland Lua exposes registered `hl.bind` callbacks, release binds, repeat/long-press flags, and `hl.timer`, but not a raw all-key event stream.

Consequences:
- Registered normal press binds compile natively and preserve Hyprland press behavior.
- Key-level tap/hold/release and registered ambiguous chords use `hl.bind` press/release sentinels plus `hl.timer` to feed the resolver.
- Unknown chords cannot suppress held-key taps in the Hyprland-native backend; `unknown_chord_policy = "registered_only"` is the honest default.
- `held_release = "cancel"` can only be enforced for held keys that the backend tracks with cycle sentinels.
- A future raw-input backend may switch to `unknown_chord_policy = "any_key"` without changing the DSL.

## Verification

Run the backend-independent resolver tests after keymap changes:

```sh
lua configs/hypr/keymap/tests.lua
```
