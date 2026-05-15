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
      writeFlake = pkgs.writeShellScriptBin "repo-write-flake" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#write-flake"
      '';

      flakeCheck = pkgs.writeShellScriptBin "repo-flake-check" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix flake check "path:$PWD"
      '';

      updateKnowledgeIndex = pkgs.writeShellScriptBin "repo-update-knowledge-index" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#newxos" -- memory reindex
      '';

      reinstallGitHooks = pkgs.writeShellScriptBin "repo-install-git-hooks" ''
        set -euo pipefail

        ${pkgs.nix}/bin/nix run "path:$PWD#install-git-hooks"
      '';

      repoGate = pkgs.writeShellScriptBin "repo-gate" ''
        set -euo pipefail

        real_index="$(${pkgs.git}/bin/git rev-parse --git-path index)"
        temp_index="$(${pkgs.coreutils}/bin/mktemp)"

        cleanup() {
          ${pkgs.coreutils}/bin/rm -f "$temp_index"
        }
        trap cleanup EXIT

        prepare_temp_index() {
          if [ -f "$real_index" ]; then
            ${pkgs.coreutils}/bin/cp "$real_index" "$temp_index"
          else
            : > "$temp_index"
          fi

          GIT_INDEX_FILE="$temp_index" ${pkgs.git}/bin/git add -A -- .
        }

        run_hooks() {
          GIT_INDEX_FILE="$temp_index" \
            ${pkgs.nix}/bin/nix develop "path:$PWD" -c pre-commit run --hook-stage pre-commit
        }

        attempt=1
        max_attempts=2

        while [ "$attempt" -le "$max_attempts" ]; do
          prepare_temp_index

          if run_hooks; then
            exit 0
          fi

          if [ "$attempt" -eq "$max_attempts" ]; then
            exit 1
          fi

          attempt=$((attempt + 1))
        done
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
        programs.stylua.enable = true;
      };

      pre-commit.settings.hooks.statix = {
        enable = true;
        after = [ "repo-write-flake" ];
        entry = "${pkgs.statix}/bin/statix fix";
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-write-flake = {
        enable = true;
        name = "write flake";
        description = "Regenerate flake.nix before commit.";
        entry = lib.getExe writeFlake;
        pass_filenames = false;
        always_run = true;
      };

      pre-commit.settings.hooks.repo-write-nvim-pack-lock =
        lib.mkIf (self'.packages ? write-nvim-pack-lock)
          {
            enable = true;
            name = "write nvim pack lockfile";
            description = "Regenerate the Neovim pack lockfile when flake.lock changes.";
            entry = lib.getExe self'.packages.write-nvim-pack-lock;
            after = [ "statix" ];
            files = "^flake\\.lock$";
            pass_filenames = false;
          };

      pre-commit.settings.hooks.repo-fmt = {
        enable = true;
        name = "format repo";
        description = "Format the repo after generated files are refreshed.";
        entry = "${config.treefmt.build.wrapper}/bin/treefmt";
        after = [
          "statix"
        ]
        ++ lib.optional (self'.packages ? write-nvim-pack-lock) "repo-write-nvim-pack-lock";
        pass_filenames = false;
        always_run = true;
      };

      pre-commit.settings.hooks.repo-flake-check = {
        enable = true;
        name = "flake check";
        description = "Run flake checks after formatting when staged Nix files changed.";
        entry = lib.getExe flakeCheck;
        after = [ "repo-fmt" ];
        pass_filenames = false;
        types = [ "nix" ];
      };

      pre-commit.settings.hooks.repo-update-knowledge-index = {
        enable = true;
        name = "update knowledge index";
        description = "Reindex Basic Memory when knowledge files change.";
        entry = lib.getExe updateKnowledgeIndex;
        after = [ "repo-fmt" ];
        files = "^knowledge/";
        pass_filenames = false;
      };

      pre-commit.settings.hooks.repo-install-git-hooks = {
        enable = true;
        name = "install git hooks";
        description = "Reinstall managed git hooks when the workflow module changes.";
        entry = lib.getExe reinstallGitHooks;
        after = [
          "repo-flake-check"
          "repo-update-knowledge-index"
        ];
        files = "^modules/workflow\\.nix$";
        pass_filenames = false;
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
