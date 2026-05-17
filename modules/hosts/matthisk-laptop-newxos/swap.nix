_:
let
  swapConfig = {
    boot.resumeDevice = "/dev/system/swap";
  };
in
{
  flake.modules.nixos.matthisk-laptop-newxos-base = swapConfig;
}
