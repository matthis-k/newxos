{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      repoCheck = pkgs.writeShellScriptBin "repo-check" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#write-flake"
        ${config.treefmt.build.wrapper}/bin/treefmt
        ${pkgs.nix}/bin/nix flake check "path:$PWD"
      '';
    in
    {
      pre-commit.check.enable = false;

      treefmt = {
        projectRoot = builtins.path {
          path = self;
          name = "template-treefmt-source";
          filter = path: _type: builtins.baseNameOf path != ".git";
        };
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };

      pre-commit.settings.hooks.repo-check = {
        enable = true;
        name = "write-flake, fmt, and flake check";
        description = "Regenerate flake.nix, format the repo, and run flake checks before commit.";
        entry = lib.getExe repoCheck;
        pass_filenames = false;
        always_run = true;
      };

      devShells.default = config.pre-commit.devShell;

      packages.fmt = config.treefmt.build.wrapper;
      packages.repo-check = repoCheck;
    };
}
