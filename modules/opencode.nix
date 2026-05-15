{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = ../packages/basic-memory-uv2nix;
      };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      pythonSet =
        let
          raw = pkgs.callPackage inputs.pyproject-nix.build.packages {
            python = pkgs.python3;
          };

          pybarsOverride = final: prev: {
            pybars3 = prev.pybars3.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
            });
            pymeta3 = prev.pymeta3.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
            });
          };
        in
        raw.overrideScope (
          lib.composeManyExtensions [
            inputs.pyproject-build-systems.overlays.wheel
            overlay
            pybarsOverride
          ]
        );

      basicMemoryEnv = pythonSet.mkVirtualEnv "basic-memory-env" workspace.deps.default;

      basicMemoryEnvScript = ''
        set -euo pipefail

        repo_root="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"

        memory_root="$repo_root/knowledge"
        state_root="$repo_root/.cache/basic-memory"

        mkdir -p "$memory_root" "$state_root"

        cat > "$state_root/config.json" <<EOF
        {
          "default_project": "newxos",
          "projects": {
            "newxos": {
              "path": "$memory_root",
              "mode": "local"
            }
          },
          "semantic_search_enabled": true,
          "semantic_embedding_provider": "fastembed",
          "cloud_mode": false
        }
        EOF

        export BASIC_MEMORY_CONFIG_DIR="$state_root"
        export BASIC_MEMORY_MCP_PROJECT="newxos"
        export BASIC_MEMORY_SEMANTIC_SEARCH_ENABLED="true"
        export BASIC_MEMORY_SEMANTIC_EMBEDDING_PROVIDER="fastembed"
        export BASIC_MEMORY_NO_PROMOS="1"
      '';

      basicMemoryMcpNewxos = pkgs.writeShellApplication {
        name = "basic-memory-mcp-newxos";

        runtimeInputs = [
          pkgs.git
          basicMemoryEnv
        ];

        text = ''
          ${basicMemoryEnvScript}
          exec basic-memory mcp --project newxos
        '';
      };

      wrappedOpencode = builtins.tryEval (
        inputs.nix-wrapper-modules.wrappers.opencode.wrap {
          inherit pkgs;

          settings = {
            "$schema" = "https://opencode.ai/config.json";

            autoupdate = false;

            permission = {
              external_directory = {
                "/nix/store/**" = "allow";
                "~/.config/**" = "allow";
              };

              skill.caveman = "allow";
            };

            mcp = {
              github = {
                type = "local";
                command = [
                  (lib.getExe pkgs.github-mcp-server)
                  "stdio"
                ];
                environment.GITHUB_PERSONAL_ACCESS_TOKEN = "{env:GITHUB_PERSONAL_ACCESS_TOKEN}";
                enabled = true;
              };

              nixos = {
                type = "local";
                command = [ (lib.getExe inputs'.mcp-nixos.packages.default) ];
                enabled = true;
              };

              basic-memory = {
                type = "local";
                command = [ (lib.getExe basicMemoryMcpNewxos) ];
                enabled = true;
              };
            };
          };
        }
      );
    in
    {
      packages = lib.optionalAttrs wrappedOpencode.success {
        opencode = wrappedOpencode.value;
        basic-memory-mcp-newxos = basicMemoryMcpNewxos;
      };
    };

  flake.modules.homeManager.opencode =
    { pkgs, ... }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }:
        lib.optionals (self'.packages ? opencode) [
          self'.packages.opencode
          self'.packages.basic-memory-mcp-newxos
        ]
      );

      xdg.configFile."opencode/skills/caveman/SKILL.md".source =
        ../configs/opencode/skills/caveman/SKILL.md;
    };
}
