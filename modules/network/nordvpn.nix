{ inputs, ... }:
{
  flake-file.inputs.nordvpn-flake = {
    # Newer revisions fail because the packaged 4.2.0 .deb URL now returns 404.
    url = "github:connerohnesorge/nordvpn-flake/f802a2efd8225116158371a8c85db28e7b0846dd";
    inputs.nixpkgs.follows = "nixpkgs";
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
      cliUser =
        if cfg.cliUser != null then
          cfg.cliUser
        else if cfg.users != [ ] then
          builtins.head cfg.users
        else
          "";
      boolToEnabled = v: if v then "enabled" else "disabled";
      autoConnectGroupArgs =
        lib.optional (cfg.settings.autoConnect.group != null) "--group"
        ++ lib.optional (cfg.settings.autoConnect.group != null) cfg.settings.autoConnect.group;
      autoConnectArgs = autoConnectGroupArgs ++ cfg.settings.autoConnect.target;
      networkOnlineServices = [
        "network-online.target"
      ]
      ++ lib.optional config.networking.networkmanager.enable "NetworkManager-wait-online.service";
      commandLine = args: ''"$NORDVPN" ${lib.escapeShellArgs args}'';
      setCommandArgs = args: "nordvpn_set ${lib.escapeShellArgs args}";
      setCommand =
        name: value:
        setCommandArgs [
          name
          value
        ];
      allowlistCommand = args: "allowlist_add ${lib.escapeShellArgs args}";
      settingsCommands = [
        (setCommand "technology" cfg.settings.technology)
        (setCommand "firewall" (boolToEnabled cfg.settings.firewall))
      ]
      ++ lib.optional (cfg.settings.fwmark != null) (setCommand "fwmark" cfg.settings.fwmark)
      ++ [
        (setCommand "routing" (boolToEnabled cfg.settings.routing))
        (setCommand "analytics" (boolToEnabled cfg.settings.analytics))
        (setCommand "killswitch" (boolToEnabled cfg.settings.killSwitch))
        (setCommand "threatprotectionlite" (boolToEnabled cfg.settings.threatProtectionLite))
        (setCommand "notify" (boolToEnabled cfg.settings.notify))
        (setCommand "tray" (boolToEnabled cfg.settings.tray))
        (setCommand "ipv6" (boolToEnabled cfg.settings.ipv6))
        (setCommand "meshnet" (boolToEnabled cfg.settings.meshnet))
        (setCommand "lan-discovery" (boolToEnabled cfg.settings.lanDiscovery))
        (setCommand "virtual-location" (boolToEnabled cfg.settings.virtualLocation))
        (setCommand "post-quantum" (boolToEnabled cfg.settings.postQuantum))
        (setCommandArgs (
          [
            "dns"
          ]
          ++ (if cfg.settings.dnsServers == [ ] then [ "false" ] else cfg.settings.dnsServers)
        ))
      ]
      ++ map (
        entry:
        allowlistCommand [
          "port"
          (toString entry.port)
          "protocol"
          entry.protocol
        ]
      ) cfg.settings.allowlist.ports
      ++ map (
        entry:
        allowlistCommand [
          "ports"
          (toString entry.from)
          (toString entry.to)
          "protocol"
          entry.protocol
        ]
      ) cfg.settings.allowlist.portRanges
      ++ map (
        subnet:
        allowlistCommand [
          "subnet"
          subnet
        ]
      ) cfg.settings.allowlist.subnets
      ++ lib.optionals cfg.settings.autoConnect.enable [
        (setCommandArgs (
          [
            "autoconnect"
            "true"
          ]
          ++ autoConnectArgs
        ))
      ]
      ++ lib.optional (!cfg.settings.autoConnect.enable) (setCommand "autoconnect" "false");
      connectCommand = commandLine ([ "connect" ] ++ autoConnectArgs);
      configureNordvpn = pkgs.writeShellScript "configure-nordvpn" ''
        set -euo pipefail

        NORDVPN=/run/current-system/sw/bin/nordvpn

        allowlist_add() {
          output="$("$NORDVPN" allowlist add "$@" 2>&1)" && {
            printf '%s\n' "$output"
            return 0
          }

          case "$output" in
            *"already allowlisted"*)
              printf '%s\n' "$output"
              return 0
              ;;
          esac

          printf '%s\n' "$output" >&2
          return 1
        }

        nordvpn_set() {
          output="$("$NORDVPN" set "$@" 2>&1)" && {
            printf '%s\n' "$output"
            return 0
          }

          case "$output" in
            *already*)
              printf '%s\n' "$output"
              return 0
              ;;
          esac

          printf '%s\n' "$output" >&2
          return 1
        }

        ${lib.concatStringsSep "\n" settingsCommands}

        ${lib.optionalString cfg.settings.autoConnect.enable ''
          if ! "$NORDVPN" status | ${pkgs.gnugrep}/bin/grep -q 'Status: Connected'; then
            ${connectCommand}
          fi
        ''}
      '';
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

            group = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Optional server group passed as `--group <group>` for auto-connect.
              '';
            };
          };

          analytics = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether NordVPN analytics should be enabled.";
          };

          allowlist = {
            ports = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    port = lib.mkOption {
                      type = lib.types.port;
                      description = "Port to allow through the NordVPN firewall.";
                    };

                    protocol = lib.mkOption {
                      type = lib.types.enum [
                        "TCP"
                        "UDP"
                      ];
                      description = "Protocol for the allowlisted port.";
                    };
                  };
                }
              );
              default = [ ];
              description = "Ports to allow through NordVPN's firewall.";
            };

            portRanges = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    from = lib.mkOption {
                      type = lib.types.port;
                      description = "First port in the allowlisted range.";
                    };

                    to = lib.mkOption {
                      type = lib.types.port;
                      description = "Last port in the allowlisted range.";
                    };

                    protocol = lib.mkOption {
                      type = lib.types.enum [
                        "TCP"
                        "UDP"
                      ];
                      description = "Protocol for the allowlisted port range.";
                    };
                  };
                }
              );
              default = [ ];
              description = "Port ranges to allow through NordVPN's firewall.";
            };

            subnets = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Subnets to allow through NordVPN's firewall.";
            };
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

          fwmark = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Optional firewall mark for NordVPN policy routing, for example `0xe1f1`.
              Leave null to keep the NordVPN default.
            '';
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

          resetDefaults = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether to run `nordvpn set defaults` before applying declarative settings.
            '';
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

      config = lib.mkIf cfg.enable {
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
          {
            assertion = lib.all (entry: entry.from <= entry.to) cfg.settings.allowlist.portRanges;
            message = "services.nordvpn.settings.allowlist.portRanges entries must have from <= to.";
          }
        ];

        systemd.services.nordvpn-bootstrap = {
          description = "Bootstrap NordVPN login and settings";
          after = networkOnlineServices ++ [ "nordvpn.service" ];
          wants = networkOnlineServices ++ [ "nordvpn.service" ];
          wantedBy = [ "multi-user.target" ];
          restartTriggers = [
            "${cfg.settings.technology}"
            "${boolToEnabled cfg.settings.firewall}"
            "${toString cfg.settings.fwmark}"
            "${boolToEnabled cfg.settings.routing}"
            "${boolToEnabled cfg.settings.analytics}"
            "${boolToEnabled cfg.settings.killSwitch}"
            "${boolToEnabled cfg.settings.threatProtectionLite}"
            "${boolToEnabled cfg.settings.notify}"
            "${boolToEnabled cfg.settings.tray}"
            "${boolToEnabled cfg.settings.ipv6}"
            "${boolToEnabled cfg.settings.meshnet}"
            "${boolToEnabled cfg.settings.lanDiscovery}"
            "${boolToEnabled cfg.settings.virtualLocation}"
            "${boolToEnabled cfg.settings.postQuantum}"
            "${boolToEnabled cfg.settings.resetDefaults}"
            "${boolToEnabled cfg.settings.autoConnect.enable}"
            "${toString cfg.settings.autoConnect.group}"
            "${lib.concatStrings cfg.settings.autoConnect.target}"
            "${lib.concatStrings cfg.settings.dnsServers}"
            "${builtins.toJSON cfg.settings.allowlist.ports}"
            "${builtins.toJSON cfg.settings.allowlist.portRanges}"
            "${builtins.toJSON cfg.settings.allowlist.subnets}"
            cliUser
          ];
          serviceConfig = {
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "30s";
            Type = "oneshot";
          };
          script = ''
            set -euo pipefail

            nordvpn() {
              ${pkgs.util-linux}/bin/runuser -u ${lib.escapeShellArg cliUser} -- /run/current-system/sw/bin/nordvpn "$@"
            }

            fail_bootstrap() {
              printf 'error: %s\n' "$1" >&2
              exit 1
            }

            attempt=0
            until nordvpn settings >/dev/null 2>&1; do
              attempt=$((attempt + 1))

              if [ "$attempt" -ge 30 ]; then
                fail_bootstrap "nordvpn CLI did not become ready"
              fi

              sleep 1
            done

            ${lib.optionalString cfg.settings.resetDefaults ''
              nordvpn set defaults
            ''}

            if ! nordvpn account >/dev/null 2>&1; then
              token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < /run/secrets/nordvpn_token)"
              if ! nordvpn login --token "$token"; then
                fail_bootstrap "nordvpn login failed"
              fi
            fi

            ${pkgs.util-linux}/bin/runuser -u ${lib.escapeShellArg cliUser} -- ${configureNordvpn}
          '';
        };
      };
    };
}
