{ inputs, lib, ... }:
let
  homeNetworkPublicKey = builtins.readFile ../../../secrets/home_network_id.pub;
in
{
  flake.modules.nixos.matthisk =
    { config, pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        fish
        git
      ];

      users.users.matthisk = {
        isNormalUser = true;
        initialPassword = lib.mkDefault "";
        description = "matthisk";
        openssh.authorizedKeys.keys = [ homeNetworkPublicKey ];
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "audio"
        ];
      };

      services.openssh = {
        enable = true;
        settings = {
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
        };
      };

      sops.secrets.home_network_id = {
        format = "binary";
        mode = "0600";
        owner = "matthisk";
        path = "/run/secrets/home_network_id";
        sopsFile = ../../../secrets/home_network_id;
      };

      home-manager.users.matthisk = lib.mkMerge [
        {
          imports = [
            inputs.self.modules.homeManager.matthisk
          ];
        }
        (lib.mkIf config.newxos.hyprland.enableRuntimeLuaImport {
          home.file.".config/hypr/nix-import.lua".source = lib.mkForce (
            pkgs.runCommand "nix-import-symlink" { } ''
              ln -s /run/newxos/hypr/nix-import.lua "$out"
            ''
          );
        })
      ];

      security.sudo.extraRules = lib.mkAfter [
        {
          users = [ "matthisk" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/cat /var/lib/sops-nix/key.txt";
              options = [ "PASSWD" ];
            }
          ];
        }
      ];
    };
}
