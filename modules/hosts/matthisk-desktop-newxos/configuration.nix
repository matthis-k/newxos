{
  inputs,
  lib,
  withSystem,
  ...
}:
let
  hyprlandWrapper = inputs.self.lib.wrapper-modules.hyprland;
in
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
    ];

    services.llm-server = {
      enableKokoroTTS = true;
    };

    networking.hostName = "matthisk-desktop-newxos";
    programs.hyprland.package = lib.mkForce (
      withSystem "x86_64-linux" (
        { pkgs, inputs', ... }:
        hyprlandWrapper.wrap {
          inherit pkgs;
          configDirectory = ../../../configs/hypr;
          package = inputs'.hyprland.packages.hyprland;
          luaVariables = {
            monitors = [ ];
          };
        }
      )
    );
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
      settings.autoConnect = {
        group = "Dedicated_IP";
        target = [ ];
      };
      settings.allowlist = {
        ports = [
          {
            port = 5353;
            protocol = "UDP";
          }
        ];
        subnets = [ "224.0.0.0/24" ];
      };
      users = [ "matthisk" ];
    };
  };
}
