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
    {
      config,
      options,
      pkgs,
      ...
    }:
    let
      stylixEnabled = builtins.hasAttr "stylix" options;
      iconThemeName =
        if config.stylix.polarity == "light" then config.stylix.icons.light else config.stylix.icons.dark;
    in
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }:
        [
          pkgs.quickshell
          self'.packages.newshell
        ]
      );

      home.sessionVariables = lib.mkIf stylixEnabled {
        QS_ICON_THEME = iconThemeName;
      };
    };
}
