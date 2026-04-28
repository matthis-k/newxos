{ inputs, lib, ... }:
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
      description = "matthisk";
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "audio"
      ];
    };

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
      fish
      git
      hyprland
      kitty
      neovim
      opencode
      sops
      zen-browser
    ];

    home.username = "matthisk";
    home.homeDirectory = "/home/matthisk";
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };
  };
}
