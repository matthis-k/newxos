_: {
  perSystem =
    { pkgs, ... }:
    let
      nordvpnLinux = pkgs.fetchFromGitHub {
        owner = "NordSecurity";
        repo = "nordvpn-linux";
        rev = "9d0e414d9490b1dd475f67e46c64ed80b623c1dc";
        hash = "sha256-i0y8oDf3trTMoiGwe5SGF6aG4Csx5b+GqGIZUS72XXY=";
      };
    in
    {
      packages.nordvpn-watch = pkgs.writeShellApplication {
        name = "nordvpn-watch";
        runtimeInputs = [
          pkgs.grpcurl
          pkgs.jq
        ];
        text = ''
          set -euo pipefail

          grpcurl \
            -plaintext \
            -emit-defaults \
            -import-path ${nordvpnLinux}/protobuf/daemon \
            -import-path ${nordvpnLinux}/protobuf \
            -proto service.proto \
            unix:///run/nordvpn/nordvpnd.sock \
            pb.Daemon/SubscribeToStateChanges \
            | jq --unbuffered -c '
                if has("connectionStatus") then { type: "status" }
                elif has("settingsChange") then { type: "settings" }
                elif has("updateEvent") then { type: "destinations" }
                else { type: "event" }
                end
              '
        '';
      };
    };
}
