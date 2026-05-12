_: {
  flake.modules.nixos.matthisk-laptop-newxos = {
    boot.resumeDevice = "/dev/system/swap";
  };
}
