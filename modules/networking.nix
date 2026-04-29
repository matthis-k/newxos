{ inputs, ... }:
{
  flake-file.inputs.nordvpn-flake = {
    # Newer revisions fail because the packaged 4.2.0 .deb URL now returns 404.
    url = "github:connerohnesorge/nordvpn-flake/f802a2efd8225116158371a8c85db28e7b0846dd";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.networking = {
    hardware.bluetooth.enable = true;
    networking.networkmanager.enable = true;
  };

  flake.modules.nixos.nordvpn =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.nordvpn;
      boolToCli = enabled: if enabled then "true" else "false";
      cliUser =
        if cfg.cliUser != null then
          cfg.cliUser
        else if cfg.users != [ ] then
          builtins.head cfg.users
        else
          "";
      dnsArgs = lib.escapeShellArgs cfg.settings.dnsServers;
    in
    {
      imports = [ inputs.nordvpn-flake.nixosModules.default ];

      options.services.nordvpn = {
        cliUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            User whose NordVPN session and CLI settings should be managed. When
            unset, the first user in `services.nordvpn.users` is used.
          '';
        };

        settings = {
          autoConnect = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether NordVPN auto-connect should be enabled.";
            };

            target = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "Dedicated_IP" ];
              description = ''
                Positional auto-connect target arguments, such as
                `[ "Dedicated_IP" ]`, `[ "us" ]`, or
                `[ "Hungary" "Budapest" ]`.
              '';
            };
          };

          analytics = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether NordVPN analytics should be enabled.";
          };

          dnsServers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              Custom DNS servers to configure. Leave empty to keep DNS disabled.
            '';
          };

          firewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether NordVPN's firewall setting should be enabled.";
          };

          ipv6 = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether NordVPN IPv6 support should be enabled.";
          };

          killSwitch = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the NordVPN kill switch should be enabled.";
          };

          lanDiscovery = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether LAN discovery should stay enabled while on VPN.";
          };

          meshnet = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether Meshnet should be enabled.

              Note: on this host, `nordvpn set meshnet on` currently fails because
              NordVPN tries to update `/etc/hosts`, which is read-only under this
              NixOS setup.
            '';
          };

          notify = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether NordVPN notifications should be enabled.";
          };

          postQuantum = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether post-quantum VPN should be enabled.";
          };

          routing = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether NordVPN traffic routing should be enabled.";
          };

          technology = lib.mkOption {
            type = lib.types.enum [
              "NORDLYNX"
              "OPENVPN"
              "NORDWHISPER"
            ];
            default = "NORDLYNX";
            description = "NordVPN connection technology.";
          };

          threatProtectionLite = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether Threat Protection Lite should be enabled.";
          };

          tray = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether NordVPN's tray icon should be enabled.";
          };

          virtualLocation = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether NordVPN virtual locations should be enabled.";
          };
        };
      };

      config = {
        assertions = [
          {
            assertion = cfg.users != [ ] || cfg.cliUser != null;
            message = "services.nordvpn requires at least one user or an explicit cliUser.";
          }
          {
            assertion = cfg.cliUser == null || lib.elem cfg.cliUser cfg.users;
            message = "services.nordvpn.cliUser must also be listed in services.nordvpn.users.";
          }
          {
            assertion = builtins.length cfg.settings.dnsServers <= 3;
            message = "services.nordvpn.settings.dnsServers can contain at most 3 servers.";
          }
          {
            assertion = !(cfg.settings.dnsServers != [ ] && cfg.settings.threatProtectionLite);
            message = "services.nordvpn.settings.dnsServers cannot be used together with threatProtectionLite.";
          }
          {
            assertion = !(cfg.settings.postQuantum && cfg.settings.meshnet);
            message = "services.nordvpn.settings.postQuantum is incompatible with meshnet.";
          }
        ];

        sops.secrets.nordvpn_token = {
          format = "binary";
          mode = "0400";
          path = "/run/secrets/nordvpn_token";
          sopsFile = ../secrets/nordvpn_token;
        };

        services.nordvpn = {
          enable = true;
          users = [ "matthisk" ];
        };

        system.activationScripts.nordvpnBootstrap = {
          supportsDryActivation = true;
          text = ''
            case "''${NIXOS_ACTION:-}" in
              switch|test)
                echo nordvpn-bootstrap.service >> /run/nixos/activation-restart-list
                ;;
              dry-activate)
                echo nordvpn-bootstrap.service >> /run/nixos/dry-activation-restart-list
                ;;
            esac
          '';
        };

        systemd.services.nordvpn-bootstrap = {
          description = "Bootstrap NordVPN login and settings";
          after = [
            "network-online.target"
            "nordvpn.service"
          ];
          wants = [
            "network-online.target"
            "nordvpn.service"
          ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            RemainAfterExit = true;
            Type = "oneshot";
          };
          script = ''
            set -euo pipefail

            nordvpn() {
              ${pkgs.util-linux}/bin/runuser -u ${lib.escapeShellArg cliUser} -- /run/current-system/sw/bin/nordvpn "$@"
            }

            skip_bootstrap() {
              printf 'warning: %s\n' "$1" >&2
              exit 0
            }

            nordvpn_connected() {
              case "$(nordvpn status 2>/dev/null || true)" in
                *"Status: Connected"*)
                  return 0
                  ;;
                *)
                  return 1
                  ;;
              esac
            }

            try_nordvpn() {
              if ! nordvpn "$@"; then
                printf 'warning: nordvpn %s failed; continuing without blocking activation\n' "$*" >&2
              fi
            }

            try_nordvpn_set() {
              try_nordvpn set "$1" "$2"
            }

            attempt=0
            until nordvpn settings >/dev/null 2>&1; do
              attempt=$((attempt + 1))

              if [ "$attempt" -ge 30 ]; then
                skip_bootstrap "nordvpn CLI did not become ready; skipping NordVPN bootstrap for this activation"
              fi

              sleep 1
            done

            if ! nordvpn account >/dev/null 2>&1; then
              token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${config.sops.secrets.nordvpn_token.path})"
              if ! nordvpn login --token "$token"; then
                skip_bootstrap "nordvpn login failed; skipping NordVPN settings for this activation"
              fi
            fi

            try_nordvpn_set technology ${cfg.settings.technology}
            try_nordvpn_set firewall ${boolToCli cfg.settings.firewall}
            try_nordvpn_set routing ${boolToCli cfg.settings.routing}
            try_nordvpn_set analytics ${boolToCli cfg.settings.analytics}
            try_nordvpn_set killswitch ${boolToCli cfg.settings.killSwitch}
            try_nordvpn_set threatprotectionlite ${boolToCli cfg.settings.threatProtectionLite}
            try_nordvpn_set notify ${boolToCli cfg.settings.notify}
            try_nordvpn_set tray ${boolToCli cfg.settings.tray}
            try_nordvpn_set ipv6 ${boolToCli cfg.settings.ipv6}
            try_nordvpn_set meshnet ${boolToCli cfg.settings.meshnet}
            try_nordvpn_set lan-discovery ${boolToCli cfg.settings.lanDiscovery}
            try_nordvpn_set virtual-location ${boolToCli cfg.settings.virtualLocation}
            try_nordvpn_set post-quantum ${boolToCli cfg.settings.postQuantum}

            ${
              if cfg.settings.dnsServers == [ ] then
                "try_nordvpn_set dns false"
              else
                "try_nordvpn set dns ${dnsArgs}"
            }

            if ${boolToCli cfg.settings.autoConnect.enable}; then
              try_nordvpn set autoconnect true ${lib.escapeShellArgs cfg.settings.autoConnect.target}

              if ! nordvpn_connected; then
                try_nordvpn connect ${lib.escapeShellArgs cfg.settings.autoConnect.target}
              fi
            else
              try_nordvpn_set autoconnect false
            fi
          '';
        };
      };
    };
}
