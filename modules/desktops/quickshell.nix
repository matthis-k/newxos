{
  lib,
  withSystem,
  ...
}:
let
  configDir = ../../configs/quickshell;
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.newshell = pkgs.writeShellScriptBin "newshell" ''
        exec ${lib.getExe pkgs.quickshell} -p ${configDir} "$@"
      '';
    };

  flake.modules.homeManager.quickshell =
    { pkgs, ... }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }:
        [
          pkgs.quickshell
          self'.packages.newshell
        ]
      );
    };
}
