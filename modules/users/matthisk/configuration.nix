{ inputs, lib, ... }:
{
  flake.homeConfigurations.matthisk = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      inputs.self.modules.homeManager.matthisk
    ];
  };

  flake.modules.nixos.matthisk = {
    imports = with inputs.self.modules.nixos; [ fish ];

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

    sops.secrets.github_id = {
      format = "binary";
      mode = "0600";
      owner = "matthisk";
      path = "/home/matthisk/.ssh/github_id";
      sopsFile = ../../../secrets/github_id;
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

    home.file.".ssh/github_id.pub".source = ../../../secrets/github_id.pub;

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
      matchBlocks."github.com" = {
        hostname = "github.com";
        identitiesOnly = true;
        identityFile = "~/.ssh/github_id";
        user = "git";
      };
    };
  };
}
