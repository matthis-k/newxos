{ inputs, ... }:
{
  flake.nixosConfigurations.matthisk-laptop-newxos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.modules.nixos.matthisk-laptop-newxos
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };

  flake.modules.nixos.matthisk-laptop-newxos = {
    imports = with inputs.self.modules.nixos; [
      audio
      disko
      homeManager
      hyprland
      locales
      networking
      nix
      newxos
      security
      sops
      stylix
    ];

    networking.hostName = "matthisk-laptop-newxos";
    newxos.hyprland.monitors = [
      {
        output = "eDP-1";
        mode = "1920x1080";
        position = "0x0";
        scale = 1;
      }
    ];
    services.displayManager.autoLogin.user = "matthisk";
    system.stateVersion = "25.11";

    sops.secrets.nordvpn_token = {
      format = "binary";
      mode = "0400";
      path = "/run/secrets/nordvpn_token";
      sopsFile = ../../../secrets/nordvpn_token;
    };

    services.nordvpn = {
      enable = true;
      users = [ "matthisk" ];
    };
  };
}
