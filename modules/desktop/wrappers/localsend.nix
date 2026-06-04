{
  inputs,
  ...
}:
let
  localsend = inputs.nix-wrapper-modules.lib.wrapModule (
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      configuredSettings =
        lib.mapAttrs' (name: value: {
          name = "flutter.${name}";
          inherit value;
        }) config.settings
        // {
          "flutter.ls_version" = 2;
          "flutter.ls_port" = config.port;
        }
        // lib.optionalAttrs (config.alias != null) {
          "flutter.ls_alias" = config.alias;
        };

      configuredSettingsFile = pkgs.writeText "localsend-settings.json" (
        builtins.toJSON configuredSettings
      );
    in
    {
      options.alias = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "LocalSend device alias shown to other devices on the LAN.";
      };

      options.port = lib.mkOption {
        type = lib.types.port;
        default = 53317;
        description = "LocalSend receive/discovery port.";
      };

      options.settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          LocalSend shared-preferences settings keyed without the `flutter.`
          prefix, for example `ls_minimize_to_tray`, `ls_https`, or `ls_quick_save`.
        '';
      };

      options.startHidden = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether LocalSend should start hidden in the tray.";
      };

      config = {
        binName = "localsend_app";
        flags = lib.optionalAttrs config.startHidden {
          "--hidden" = true;
        };
        runtimePkgs = [ pkgs.jq ];
        runShell = [
          ''
            settings_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/org.localsend.localsend_app"
            settings_file="$settings_dir/shared_preferences.json"
            mkdir -p "$settings_dir"

            if [ -f "$settings_file" ]; then
              tmp_file="$(mktemp)"
              jq -s '.[0] * .[1]' "$settings_file" ${configuredSettingsFile} > "$tmp_file"
              mv "$tmp_file" "$settings_file"
            else
              cp ${configuredSettingsFile} "$settings_file"
            fi
          ''
        ];
        meta.description = "Wrapped LocalSend app with newxos defaults.";
      };
    }
  );
in
{
  flake.modules.nixos.localsend =
    { config, pkgs, ... }:
    let
      localsendPort = 53317;
      hostPkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      localsendPackage = localsend.wrap {
        pkgs = hostPkgs;
        package = hostPkgs.localsend;
        alias = config.networking.hostName;
        port = localsendPort;
      };
    in
    {
      programs.localsend = {
        enable = true;
        package = localsendPackage;
        openFirewall = true;
      };

      services.nordvpn.settings.allowlist.ports = [
        {
          port = localsendPort;
          protocol = "TCP";
        }
        {
          port = localsendPort;
          protocol = "UDP";
        }
      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.localsend = pkgs.localsend;

      packages.newxos-localsend = localsend.wrap {
        inherit pkgs;
        package = pkgs.localsend;
        port = 53317;
      };
    };
}
