_: {
  flake.modules.homeManager.stylix-quickshell =
    { config, pkgs, ... }:
    let
      c = config.stylix.fullPalette.colors;
      paletteJson = pkgs.writeText "quickshell-catppuccin-palette.json" (
        builtins.toJSON {
          name = config.stylix.fullPalette.name;
          flavor = config.stylix.fullPalette.flavor;
          author = config.stylix.fullPalette.author;
          colors = {
            inherit (c) rosewater;
            inherit (c) flamingo;
            inherit (c) pink;
            inherit (c) mauve;
            inherit (c) red;
            inherit (c) maroon;
            inherit (c) peach;
            inherit (c) yellow;
            inherit (c) green;
            inherit (c) teal;
            inherit (c) sky;
            inherit (c) sapphire;
            inherit (c) blue;
            inherit (c) lavender;
            inherit (c) text;
            inherit (c) subtext1;
            inherit (c) subtext0;
            inherit (c) overlay2;
            inherit (c) overlay1;
            inherit (c) overlay0;
            inherit (c) surface2;
            inherit (c) surface1;
            inherit (c) surface0;
            inherit (c) base;
            inherit (c) mantle;
            inherit (c) crust;
          };
        }
      );
    in
    {
      xdg.configFile."quickshell/catppuccin-palette.json".source = paletteJson;
    };
}
