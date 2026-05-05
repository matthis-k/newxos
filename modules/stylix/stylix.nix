{
  inputs,
  lib,
  ...
}:
let
  defaultCatppuccinPalette = {
    name = "Catppuccin Mocha";
    flavor = "mocha";
    author = "https://github.com/catppuccin/catppuccin";
    colors = {
      rosewater = "#f5e0dc";
      flamingo = "#f2cdcd";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      subtext0 = "#a6adc8";
      overlay2 = "#9399b2";
      overlay1 = "#7f849c";
      overlay0 = "#6c7086";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };
  };

  fullPaletteType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Display name for the full theme palette.";
      };

      flavor = lib.mkOption {
        type = lib.types.str;
        description = "Palette flavor name.";
      };

      author = lib.mkOption {
        type = lib.types.str;
        description = "Palette author or upstream source.";
      };

      colors = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = ''
          Full semantic palette used by repo-specific targets such as Kitty.
          Expected keys follow the Catppuccin palette naming scheme.
        '';
      };
    };
  };

  mkBase16Scheme =
    palette:
    let
      c = palette.colors;
    in
    {
      system = "base16";
      name = palette.name;
      author = palette.author;
      variant = "dark";
      palette = {
        base00 = c.base;
        base01 = c.mantle;
        base02 = c.surface0;
        base03 = c.surface1;
        base04 = c.surface2;
        base05 = c.text;
        base06 = c.rosewater;
        base07 = c.lavender;
        base08 = c.red;
        base09 = c.peach;
        base0A = c.yellow;
        base0B = c.green;
        base0C = c.teal;
        base0D = c.blue;
        base0E = c.mauve;
        base0F = c.flamingo;
      };
    };

  mkFullPaletteOption = lib.mkOption {
    type = fullPaletteType;
    default = defaultCatppuccinPalette;
    description = ''
      Full semantic palette used as the source of truth for repo-specific theming.
      Stylix derives its Base16 scheme from this palette, and custom targets such
      as Kitty can use the full semantic colors directly.
    '';
  };
in
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.stylix =
    { config, pkgs, ... }:
    let
      fullPalette = config.stylix.fullPalette;
    in
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      options.stylix.fullPalette = mkFullPaletteOption;

      config = {
        stylix = {
          enable = true;
          base16Scheme = mkBase16Scheme fullPalette;
          homeManagerIntegration.autoImport = false;
          icons = {
            enable = true;
            package = pkgs.papirus-icon-theme;
            dark = "Papirus-Dark";
            light = "Papirus";
          };
        };

        home-manager.sharedModules = [
          {
            stylix.fullPalette = lib.mkDefault fullPalette;
          }
        ];
      };
    };

  flake.modules.homeManager.stylix =
    { config, pkgs, ... }:
    let
      fullPalette = config.stylix.fullPalette;
    in
    {
      imports = with inputs.self.modules.homeManager; [
        inputs.stylix.homeModules.stylix
        stylix-fish
        stylix-kitty
        stylix-zen-browser
      ];

      options.stylix.fullPalette = mkFullPaletteOption;

      config = {
        stylix = {
          enable = true;
          base16Scheme = mkBase16Scheme fullPalette;
          icons = {
            enable = true;
            package = pkgs.papirus-icon-theme;
            dark = "Papirus-Dark";
            light = "Papirus";
          };
        };
      };
    };
}
