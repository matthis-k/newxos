{ inputs, withSystem, ... }:
{
  flake-file.inputs.zen-flake = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  flake.modules.homeManager.zen-browser =
    { pkgs, ... }:
    let
      zenPackage = withSystem pkgs.stdenv.hostPlatform.system (
        { inputs', ... }: inputs'.zen-flake.packages.beta
      );
    in
    {
      imports = [ inputs.zen-flake.homeModules.beta ];

      programs.zen-browser = {
        enable = true;
        package = zenPackage;
      };

      home.sessionVariables.BROWSER = "zen-beta";
    };
}
