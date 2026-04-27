{ ... }:
{
  flake.modules.nixos.matthisk-laptop-nixos = {
    boot.resumeDevice = "/dev/system/swap";
  };
}
