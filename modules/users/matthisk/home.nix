{ inputs, ... }:
{
  flake.modules.homeManager.matthisk = {
    imports = with inputs.self.modules.homeManager; [
      dev-tools
      fish
      git
      hyprland
      kitty
      newxos
      neovim
      opencode
      quickshell
      sops
      stylix
      wayland-tools
      zen-browser
      matthisk-ssh
    ];

    home.username = "matthisk";
    home.homeDirectory = "/home/matthisk";
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;
  };
}
