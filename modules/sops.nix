{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { pkgs, ... }:
    let
      sopsAgeKeyCmd = pkgs.writeShellScript "sops-age-key" ''
        exec /run/wrappers/bin/sudo /run/current-system/sw/bin/cat /var/lib/sops-nix/key.txt
      '';
    in
    {
      packages.sops = pkgs.writeShellScriptBin "sops" ''
        set -euo pipefail

        export SOPS_AGE_KEY_CMD="${sopsAgeKeyCmd}"

        exec ${lib.getExe pkgs.sops} "$@"
      '';
    };

  flake.modules.nixos.sops =
    if inputs ? sops-nix then
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];

        sops.age.keyFile = "/var/lib/sops-nix/key.txt";

        systemd.tmpfiles.rules = [
          "d /var/lib/sops-nix 0700 root root -"
        ];
      }
    else
      { };

  flake.modules.homeManager.sops =
    { pkgs, ... }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: [ self'.packages.sops ]
      );
    };
}
