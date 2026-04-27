{
  inputs,
  self,
  ...
}:
let
  repoSource = builtins.path {
    path = self;
    name = "newxos-installer-source";
    filter = path: _type: builtins.baseNameOf path != ".git";
  };

  mkFirstTimeInstall =
    pkgs:
    let
      system = pkgs.stdenv.hostPlatform.system;
      diskoPackage = inputs.disko.packages.${system}.disko or inputs.disko.packages.${system}.default;
    in
    pkgs.writeShellApplication {
      name = "first-time-install";
      runtimeInputs = [
        diskoPackage
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.util-linux
      ];
      text = ''
        if [ "$#" -ne 2 ]; then
          echo "usage: first-time-install <host> <target-disk>" >&2
          exit 2
        fi

        if [ "$EUID" -ne 0 ]; then
          exec sudo "$0" "$@"
        fi

        host="$1"
        target="$2"
        flake_root=/etc/newxos
        root_mountpoint=/mnt

        if [ ! -e "$flake_root/flake.nix" ]; then
          echo "missing bundled flake at $flake_root" >&2
          exit 1
        fi

        if [ ! -b "$target" ]; then
          echo "target must be a block device path, got: $target" >&2
          exit 1
        fi

        disko \
          --mode destroy,format,mount \
          --root-mountpoint "$root_mountpoint" \
          --flake "$flake_root#$host" \
          --argstr mainDisk "$target"

        nixos-install \
          --root "$root_mountpoint" \
          --flake "$flake_root#$host" \
          --no-root-passwd
      '';
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.first-time-install = mkFirstTimeInstall pkgs;
    };

  flake.modules.nixos.installerMedia =
    { pkgs, ... }:
    let
      firstTimeInstall = mkFirstTimeInstall pkgs;
      system = pkgs.stdenv.hostPlatform.system;
      diskoPackage = inputs.disko.packages.${system}.disko or inputs.disko.packages.${system}.default;
    in
    {
      environment.etc."newxos".source = repoSource;

      environment.systemPackages = [
        pkgs.curl
        pkgs.cryptsetup
        diskoPackage
        pkgs.dosfstools
        firstTimeInstall
        pkgs.git
        pkgs.gptfdisk
        pkgs.jq
        pkgs.lvm2
        pkgs.mdadm
        pkgs.nvme-cli
        pkgs.parted
        pkgs.pciutils
        pkgs.ripgrep
        pkgs.rsync
        pkgs.usbutils
        pkgs.vim
        pkgs.wget
      ];

      system.build.first-time-install = firstTimeInstall;
    };
}
