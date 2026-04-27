-- Remote-derived defaults kept minimal for a first usable setup.

local terminal = "kitty"
local browser = "zen-beta"
local mainMod = "SUPER"

hl.config({
    general = {
        border_size = 2,
        gaps_in = 0,
        gaps_out = 0,
        layout = "scrolling",
    },

    input = {
        kb_layout = "de",
        numlock_by_default = true,

        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.9,
        follow_focus = true,
        direction = "right",
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
