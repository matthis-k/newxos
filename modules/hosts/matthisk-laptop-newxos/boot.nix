{ ... }:
{
  flake.modules.nixos.matthisk-laptop-newxos = {
    boot.initrd.systemd.enable = true;
    boot.plymouth.enable = true;

    boot.loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
      };
    };
  };
}
