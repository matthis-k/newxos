{ inputs, lib, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      mcpNixosPackages = inputs.mcp-nixos.packages.${system} or null;
    in
    {
      packages = lib.optionalAttrs (mcpNixosPackages != null) {
        opencode = inputs.nix-wrapper-modules.wrappers.opencode.wrap {
          inherit pkgs;

          settings = {
            "$schema" = "https://opencode.ai/config.json";

            mcp.nixos = {
              type = "local";
              command = [ (lib.getExe mcpNixosPackages.default) ];
              enabled = true;
            };
          };
        };
      };
    };
}
