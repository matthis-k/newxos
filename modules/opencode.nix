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

            permission.external_directory."/nix/store/**" = "allow";

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

  flake.modules.homeManager.opencode =
    { pkgs, ... }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: lib.optional (self'.packages ? opencode) self'.packages.opencode
      );
    };
}
