{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.kitty = inputs.nix-wrapper-modules.wrappers.kitty.wrap {
        inherit pkgs;

        font = {
          name = "Hack Nerd Font";
          size = 10;
        };
        themeFile = "Catppuccin-Mocha";
        extraConfig = builtins.readFile ../../configs/kitty/kitty.conf;
      };
    };

  flake.modules.homeManager.kitty =
    { pkgs, ... }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }:
        [
          self'.packages.kitty
          pkgs.nerd-fonts.hack
        ]
      );

      home.sessionVariables.TERMINAL = lib.getExe (
        withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: self'.packages.kitty)
      );
    };
}
