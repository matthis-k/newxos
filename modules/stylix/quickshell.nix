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
            rosewater = c.rosewater;
            flamingo = c.flamingo;
            pink = c.pink;
            mauve = c.mauve;
            red = c.red;
            maroon = c.maroon;
            peach = c.peach;
            yellow = c.yellow;
            green = c.green;
            teal = c.teal;
            sky = c.sky;
            sapphire = c.sapphire;
            blue = c.blue;
            lavender = c.lavender;
            text = c.text;
            subtext1 = c.subtext1;
            subtext0 = c.subtext0;
            overlay2 = c.overlay2;
            overlay1 = c.overlay1;
            overlay0 = c.overlay0;
            surface2 = c.surface2;
            surface1 = c.surface1;
            surface0 = c.surface0;
            base = c.base;
            mantle = c.mantle;
            crust = c.crust;
          };
        }
      );
    in
    {
      xdg.configFile."quickshell/catppuccin-palette.json".source = paletteJson;
    };
}
