{ ... }:
{
  flake.modules.homeManager.matthisk = {
    home.username = "matthisk";
    home.homeDirectory = "/home/matthisk";
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;
  };
}
