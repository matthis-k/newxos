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
  flake.modules.nixos.homeManager = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      homeManagerDefaults
    ];
  };
}
