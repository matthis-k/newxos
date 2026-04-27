{ inputs, withSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.neovim = inputs.nix-wrapper-modules.wrappers.neovim.wrap {
        inherit pkgs;

        settings = {
          aliases = [
            "vi"
            "vim"
          ];
          config_directory = ../../configs/nvim;
        };
      };
    };

  flake.modules.homeManager.neovim =
    { pkgs, ... }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: [ self'.packages.neovim ]
      );

      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
}
