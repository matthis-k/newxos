{ lib, ... }:
{
  flake.modules.nixos.git = {
    sops.secrets.github_id = {
      format = "binary";
      mode = "0600";
      owner = "matthisk";
      path = "/run/secrets/github_id";
      sopsFile = ../../secrets/github_id;
    };

    sops.secrets.github_token = {
      format = "binary";
      mode = "0600";
      owner = "matthisk";
      path = "/run/secrets/github_token";
      sopsFile = ../../secrets/github_token;
    };
  };

  flake.modules.homeManager.git =
    { pkgs, ... }:
    {
      programs.git = {
        enable = true;
        package = pkgs.gitFull;
        settings = {
          user.name = "matthis-k";
          user.email = "matthis.kaelble@gmail.com";

          pull.rebase = false;
          merge.conflictstyle = "diff3";
          init.defaultBranch = "main";
          core.editor = "nvim";
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };

      programs.gh.enable = true;
      programs.lazygit.enable = true;

      programs.fish.interactiveShellInit = lib.mkAfter ''
        if test -r /run/secrets/github_token
          set -l github_token (string trim < /run/secrets/github_token)

          if test -n "$github_token"
            set -gx GH_TOKEN $github_token
            set -gx GITHUB_TOKEN $github_token
            set -gx GITHUB_PERSONAL_ACCESS_TOKEN $github_token
          end
        end
      '';

      programs.ssh.matchBlocks."github.com" = {
        addKeysToAgent = "yes";
        hostname = "github.com";
        identitiesOnly = true;
        identityFile = "/run/secrets/github_id";
        user = "git";
      };
    };
}
