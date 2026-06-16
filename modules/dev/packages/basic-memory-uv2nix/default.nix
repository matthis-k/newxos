{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      workspaceRoot = ../../../../packages/basic-memory-uv2nix;

      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        inherit workspaceRoot;
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
    in
    {
      options.newxos.basicMemoryUv2nix = lib.mkOption {
        type = lib.types.package;
        internal = true;
      };

      config = {
        newxos.basicMemoryUv2nix = basicMemoryEnv;
        packages.basic-memory-uv2nix = basicMemoryEnv;
      };
    };
}
