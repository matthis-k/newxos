{ ... }:
{
  flake.modules.nixos.git = {
    sops.secrets.github_id = {
      format = "binary";
      mode = "0600";
      owner = "matthisk";
      path = "/home/matthisk/.ssh/github_id";
      sopsFile = ../../secrets/github_id;
    };
  };

  flake.modules.homeManager.git =
    { pkgs, ... }:
    {
      home.file.".ssh/github_id.pub".source = ../../secrets/github_id.pub;

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

      programs.gh.enable = true;
      programs.lazygit.enable = true;

      programs.ssh.matchBlocks."github.com" = {
        hostname = "github.com";
        identitiesOnly = true;
        identityFile = "~/.ssh/github_id";
        user = "git";
      };
    };
}
