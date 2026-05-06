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
      self',
      ...
    }:
    let
      repoGate = pkgs.writeShellScriptBin "repo-gate" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#write-flake"
        ${lib.optionalString (self'.packages ? write-nvim-pack-lock) ''
          ${lib.getExe self'.packages.write-nvim-pack-lock}
        ''}
        ${config.treefmt.build.wrapper}/bin/treefmt
        ${pkgs.nix}/bin/nix flake check "path:$PWD"
      '';
    in
    {
      pre-commit.check.enable = false;

      treefmt = {
        projectRoot = builtins.path {
          path = self;
          name = "newxos-treefmt-source";
          filter = path: _type: builtins.baseNameOf path != ".git";
        };
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };

      pre-commit.settings.hooks.repo-gate = {
        enable = true;
        name = "write-flake, fmt, and flake check";
        description = "Regenerate flake.nix, format the repo, and run flake checks before commit.";
        entry = lib.getExe repoGate;
        pass_filenames = false;
        always_run = true;
      };

      devShells.default = config.pre-commit.devShell;

      packages.fmt = config.treefmt.build.wrapper;
      packages.install-git-hooks = pkgs.writeShellScriptBin "install-git-hooks" ''
        set -euo pipefail
        ${config.pre-commit.installationScript}
      '';
      packages.repo-gate = repoGate;
    };
}
