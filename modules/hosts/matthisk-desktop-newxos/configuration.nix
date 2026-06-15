{ inputs, ... }:
{
  flake.nixosConfigurations.matthisk-desktop-newxos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.modules.nixos.matthisk-desktop-newxos
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };

  flake.modules.nixos.matthisk-desktop-newxos = {
    imports = with inputs.self.modules.nixos; [
      common-workstation
      matthisk
      llm-server
      devSpecialization
    ];

    services.llm-server = {
      enableTTS = true;
    };

    networking.hostName = "matthisk-desktop-newxos";

    newxos.hyprland.monitors = [ ];

    newxos.nordvpn.enable = true;
    newxos.nordvpn.technology = "NORDLYNX";

    sops.secrets.nordvpn_token = {
      format = "binary";
      mode = "0400";
      path = "/run/secrets/nordvpn_token";
      sopsFile = ../../../secrets/nordvpn_token;
    };

    services.displayManager.autoLogin.user = "matthisk";
    system.stateVersion = "25.11";
  };
}
