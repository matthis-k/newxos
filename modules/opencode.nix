{ inputs, lib, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.opencode = inputs.nix-wrapper-modules.wrappers.opencode.wrap {
        inherit pkgs;

        settings = {
          "$schema" = "https://opencode.ai/config.json";

          mcp.nixos = {
            type = "local";
            command = [
              (lib.getExe' pkgs.uv "uvx")
              "mcp-nixos"
            ];
            enabled = true;
          };
        };
      };
    };
}
