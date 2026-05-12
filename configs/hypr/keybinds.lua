local function dispatch_all(...)
    local dispatchers = { ... }

    return function()
        for _, dispatcher in ipairs(dispatchers) do
            hl.dispatch(dispatcher)
        end
    end
end

local function repeat_dispatch(dispatcher, times)
    return function()
        for _ = 1, times do
            hl.dispatch(dispatcher)
        end
    end
end

local keybinds = {
    keybinds = {
        { "SUPER + Return", hl.dsp.exec_cmd("kitty") },
        { "SUPER + D", hl.dsp.exec_cmd("newshell ipc call applauncher toggle") },
        { "CTRL + ALT + W", hl.dsp.exec_cmd("zen-beta") },
        { "Print", hl.dsp.exec_cmd("screen-shot region") },
        { "SUPER + SHIFT + S", hl.dsp.exec_cmd("screen-shot region-direct") },
        { "SUPER + SHIFT + E", hl.dsp.exec_cmd("screen-edit-clipboard") },
        { "SHIFT + Print", hl.dsp.exec_cmd("screen-shot output") },
        { "CTRL + Print", hl.dsp.exec_cmd("screen-shot window") },
        { "SUPER + Print", hl.dsp.exec_cmd("screen-read-region") },
        { "SUPER + Q", hl.dsp.window.close() },
        { "SUPER + M", hl.dsp.submap("window_manipulation") },
        { "SUPER + H", hl.dsp.focus({ direction = "left" }) },
        { "SUPER + L", hl.dsp.focus({ direction = "right" }) },
        { "SUPER + up", hl.dsp.focus({ direction = "up" }) },
        { "SUPER + down", hl.dsp.focus({ direction = "down" }) },
        { "SUPER + J", hl.dsp.focus({ workspace = "+1" }) },
        { "SUPER + K", hl.dsp.focus({ workspace = "-1" }) },
        { "SUPER + mouse_down", hl.dsp.focus({ workspace = "+1" }) },
        { "SUPER + mouse_up", hl.dsp.focus({ workspace = "-1" }) },
        { "SUPER + SHIFT + H", hl.dsp.layout("swapcol l") },
        { "SUPER + SHIFT + J", hl.dsp.window.move({ workspace = "+1" }) },
        { "SUPER + SHIFT + K", hl.dsp.window.move({ workspace = "-1" }) },
        { "SUPER + SHIFT + L", hl.dsp.layout("swapcol r") },
        { "SUPER + 1", hl.dsp.focus({ workspace = 1 }) },
        { "SUPER + 2", hl.dsp.focus({ workspace = 2 }) },
        { "SUPER + 3", hl.dsp.focus({ workspace = 3 }) },
        { "SUPER + 4", hl.dsp.focus({ workspace = 4 }) },
        { "SUPER + 5", hl.dsp.focus({ workspace = 5 }) },
        { "SUPER + 6", hl.dsp.focus({ workspace = 6 }) },
        { "SUPER + 7", hl.dsp.focus({ workspace = 7 }) },
        { "SUPER + 8", hl.dsp.focus({ workspace = 8 }) },
        { "SUPER + 9", hl.dsp.focus({ workspace = 9 }) },
        { "SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }) },
        { "SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }) },
        { "SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }) },
        { "SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }) },
        { "SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }) },
        { "SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }) },
        { "SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }) },
        { "SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }) },
        { "SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }) },
        { "XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },
        { "XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") },
        { "XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") },
        { "XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous") },
        { "XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause") },
        { "XF86AudioNext", hl.dsp.exec_cmd("playerctl next") },
        { "XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 -c leds set 50%-") },
        { "XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 -c leds set 50%+") },
        { "XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 -c backlight set 5%-") },
        { "XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 -c backlight set 5%+") },
    },
    submaps = {
        window_manipulation = {
            keybinds = {
                { "H", hl.dsp.layout("swapcol l") },
                { "J", hl.dsp.window.move({ workspace = "+1", follow = true }) },
                { "K", hl.dsp.window.move({ workspace = "-1", follow = true }) },
                { "L", hl.dsp.layout("swapcol r") },
                { "P", hl.dsp.layout("promote") },
                { "SHIFT + H", hl.dsp.window.move({ direction = "left" }) },
                { "SHIFT + J", hl.dsp.window.move({ direction = "down" }) },
                { "SHIFT + K", hl.dsp.window.move({ direction = "up" }) },
                { "SHIFT + L", hl.dsp.window.move({ direction = "right" }) },
                { "minus", hl.dsp.layout("colresize -conf") },
                { "plus", hl.dsp.layout("colresize +conf") },
                { "Escape", hl.dsp.submap("reset") },
                { "Return", hl.dsp.submap("reset") },
            },
        },
    },
}

local function register(scope, name)
    local function register_callback()
        for _, bind in ipairs(scope.keybinds or {}) do
            hl.bind(bind[1], bind[2])
        end

        for child_name, child_scope in pairs(scope.submaps or {}) do
            register(child_scope, child_name)
        end
    end

    if name == nil then
        register_callback()
    elseif scope.reset_to ~= nil then
        hl.define_submap(name, scope.reset_to, register_callback)
    else
        hl.define_submap(name, register_callback)
    end
end

register(keybinds)
