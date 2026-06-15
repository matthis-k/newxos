{ inputs, ... }:
{
  flake.homeConfigurations.matthisk = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      inputs.self.modules.homeManager.matthisk
    ];
  };
}
