{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  perSystem =
    {
      inputs',
      pkgs,
      ...
    }:
    let
      wrappedOpencode = builtins.tryEval (
        inputs.nix-wrapper-modules.wrappers.opencode.wrap {
          inherit pkgs;

          settings = {
            "$schema" = "https://opencode.ai/config.json";

            mcp.nixos = {
              type = "local";
              command = [ (lib.getExe inputs'.mcp-nixos.packages.default) ];
              enabled = true;
            };
          };
        }
      );
    in
    {
      packages = lib.optionalAttrs wrappedOpencode.success {
        opencode = wrappedOpencode.value;
      };
    };

  flake.modules.nixos.opencode =
    { pkgs, ... }:
    {
      environment.systemPackages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: lib.optional (self'.packages ? opencode) self'.packages.opencode
      );
    };
}
