{ inputs, lib, ... }:
let
  homeNetworkPublicKey = builtins.readFile ../../../secrets/home_network_id.pub;
in
{
  flake.homeConfigurations.matthisk = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      inputs.self.modules.homeManager.matthisk
    ];
  };

  flake.modules.nixos.matthisk = {
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

    home-manager.users.matthisk.imports = [
      inputs.self.modules.homeManager.matthisk
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
      zen-browser
    ];

    home.username = "matthisk";
    home.homeDirectory = "/home/matthisk";
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };

        "matthisk-desktop-newxos desktop" = {
          HostName = "matthisk-desktop-newxos.local";
          IdentitiesOnly = true;
          IdentityFile = "/run/secrets/home_network_id";
          User = "matthisk";
        };

        "matthisk-laptop-newxos laptop" = {
          HostName = "matthisk-laptop-newxos.local";
          IdentitiesOnly = true;
          IdentityFile = "/run/secrets/home_network_id";
          User = "matthisk";
        };
      };
    };
  };
}
