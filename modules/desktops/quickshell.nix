{
  lib,
  withSystem,
  ...
}:
let
  configDir = builtins.path {
    name = "quickshell-config";
    path = ../../configs/quickshell;
    filter = path: type: !(type == "regular" && builtins.baseNameOf path == ".qmlls.ini");
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.newshell = pkgs.writeShellScriptBin "newshell" ''
        config_dir=${configDir}
        local_config_root="''${NEWXOS_FLAKE_PATH:-$HOME/newxos}"
        args=()

        for arg in "$@"; do
          if [[ "$arg" == "--local" ]]; then
            config_dir="$local_config_root/configs/quickshell"

            if [[ ! -f "$local_config_root/flake.nix" || ! -d "$config_dir" ]]; then
              printf 'newshell: invalid NEWXOS_FLAKE_PATH: %s\n' "$local_config_root" >&2
              exit 1
            fi

            continue
          fi

          args+=("$arg")
        done

        exec ${lib.getExe pkgs.quickshell} -p "$config_dir" "''${args[@]}"
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
