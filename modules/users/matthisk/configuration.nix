{ inputs, ... }:
{
  flake.homeConfigurations.matthisk = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      inputs.self.modules.homeManager.matthisk
    ];
  };

  flake.modules.nixos.matthisk = {
    users.users.matthisk = {
      isNormalUser = true;
      description = "matthisk";
      extraGroups = [ "wheel" ];
    };
  };

  flake.modules.homeManager.matthisk = {
    home.username = "matthisk";
    home.homeDirectory = "/home/matthisk";
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;
  };
}
