{ inputs, ... }:
let
  homeManagerDefaults = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
in
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.modules.nixos.homeManager = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      homeManagerDefaults
    ];
  };
}
