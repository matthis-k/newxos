{ lib, ... }:
{
  flake.modules.homeManager.stylix-fish =
    { config, ... }:
    let
      c = config.stylix.fullPalette.colors;
      hex = color: lib.removePrefix "#" color;
    in
    {
      stylix.targets.fish.enable = false;

      xdg.configFile."fish/stylix-theme.auto.fish".text = ''
        # Generated from config.stylix.fullPalette.
        # Layout matches the official catppuccin/fish static theme.

        set -g fish_color_normal ${hex c.text}
        set -g fish_color_command ${hex c.blue}
        set -g fish_color_param ${hex c.flamingo}
        set -g fish_color_keyword ${hex c.mauve}
        set -g fish_color_quote ${hex c.green}
        set -g fish_color_redirection ${hex c.pink}
        set -g fish_color_end ${hex c.peach}
        set -g fish_color_comment ${hex c.overlay1}
        set -g fish_color_error ${hex c.red}
        set -g fish_color_gray ${hex c.overlay0}
        set -g fish_color_selection '--background=${hex c.surface0}'
        set -g fish_color_search_match '--background=${hex c.surface0}'
        set -g fish_color_option ${hex c.green}
        set -g fish_color_operator ${hex c.pink}
        set -g fish_color_escape ${hex c.maroon}
        set -g fish_color_autosuggestion ${hex c.overlay0}
        set -g fish_color_cancel ${hex c.red}
        set -g fish_color_cwd ${hex c.yellow}
        set -g fish_color_user ${hex c.teal}
        set -g fish_color_host ${hex c.blue}
        set -g fish_color_host_remote ${hex c.green}
        set -g fish_color_status ${hex c.red}
        set -g fish_pager_color_progress ${hex c.overlay0}
        set -g fish_pager_color_prefix ${hex c.pink}
        set -g fish_pager_color_completion ${hex c.text}
        set -g fish_pager_color_description ${hex c.overlay0}
      '';

      programs.fish.interactiveShellInit = lib.mkBefore ''
        source ~/.config/fish/stylix-theme.auto.fish
      '';
    };
}
