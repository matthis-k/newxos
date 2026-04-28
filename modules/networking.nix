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
      pkgs,
      ...
    }:
    {
      imports = [ inputs.nordvpn-flake.nixosModules.default ];

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

      systemd.services.nordvpn-login-if-needed = {
        description = "Login to NordVPN if needed";
        after = [
          "network-online.target"
          "nordvpn.service"
        ];
        wants = [
          "network-online.target"
          "nordvpn.service"
        ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail

          if ${pkgs.util-linux}/bin/runuser -u matthisk -- /run/current-system/sw/bin/nordvpn account >/dev/null 2>&1; then
            exit 0
          fi

          token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${config.sops.secrets.nordvpn_token.path})"

          exec ${pkgs.util-linux}/bin/runuser -u matthisk -- /run/current-system/sw/bin/nordvpn login --token "$token"
        '';
      };
    };
}
