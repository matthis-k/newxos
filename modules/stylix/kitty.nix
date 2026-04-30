{ ... }:
{
  flake.modules.homeManager.stylix-kitty =
    { config, ... }:
    let
      c = config.stylix.fullPalette.colors;
    in
    {
      stylix.targets.kitty.enable = false;

      xdg.configFile."kitty/stylix-theme.auto.conf".text = ''
        # vim:ft=kitty
        # Generated from config.stylix.fullPalette.
        # Layout matches the official catppuccin/kitty Mocha port.

        # The basic colors
        foreground              ${c.text}
        background              ${c.base}
        selection_foreground    ${c.base}
        selection_background    ${c.rosewater}

        # Cursor colors
        cursor                  ${c.rosewater}
        cursor_text_color       ${c.base}

        # Scrollbar colors
        scrollbar_handle_color  ${c.overlay2}
        scrollbar_track_color   ${c.surface1}

        # URL color when hovering with mouse
        url_color               ${c.rosewater}

        # Kitty window border colors
        active_border_color     ${c.lavender}
        inactive_border_color   ${c.overlay0}
        bell_border_color       ${c.yellow}

        # OS Window titlebar colors
        wayland_titlebar_color system
        macos_titlebar_color system

        # Tab bar colors
        active_tab_foreground   ${c.crust}
        active_tab_background   ${c.mauve}
        inactive_tab_foreground ${c.text}
        inactive_tab_background ${c.mantle}
        tab_bar_background      ${c.crust}

        # Colors for marks (marked text in the terminal)
        mark1_foreground ${c.base}
        mark1_background ${c.lavender}
        mark2_foreground ${c.base}
        mark2_background ${c.mauve}
        mark3_foreground ${c.base}
        mark3_background ${c.sapphire}

        # The 16 terminal colors

        # black
        color0 ${c.surface1}
        color8 ${c.surface2}

        # red
        color1 ${c.red}
        color9 ${c.red}

        # green
        color2  ${c.green}
        color10 ${c.green}

        # yellow
        color3  ${c.yellow}
        color11 ${c.yellow}

        # blue
        color4  ${c.blue}
        color12 ${c.blue}

        # magenta
        color5  ${c.pink}
        color13 ${c.pink}

        # cyan
        color6  ${c.teal}
        color14 ${c.teal}

        # white
        color7  ${c.subtext1}
        color15 ${c.subtext0}
      '';
    };
}
