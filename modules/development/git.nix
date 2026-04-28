{ ... }:
{
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

      programs.gh.enable = true;
      programs.lazygit.enable = true;
    };
}
