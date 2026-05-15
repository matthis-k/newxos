{
  lib,
  withSystem,
  ...
}:
{
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
          self'.packages.quickshell
          self'.packages.newshell
          self'.packages.newshelldev
          pkgs.kdePackages.qtdeclarative
          pkgs.kdePackages.qt3d
          pkgs.kdePackages.qt6ct
          pkgs.kdePackages.qtbase
          pkgs.kdePackages.qttools
          pkgs.kdePackages.qt5compat
        ]
      );

      home.sessionVariables = lib.mkIf stylixEnabled {
        QS_ICON_THEME = iconThemeName;
      };

      systemd.user.services.newshell = {
        Unit = {
          Description = "Quickshell session";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = withSystem pkgs.stdenv.hostPlatform.system (
          { self', ... }:
          {
            ExecStart = lib.getExe self'.packages.newshell;
            Restart = "on-failure";
            RestartSec = "500ms";
            Environment = [
              "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/wrappers/bin:/run/current-system/sw/bin"
              "XDG_CURRENT_DESKTOP=Hyprland"
            ];
          }
        );
      };
    };
}
