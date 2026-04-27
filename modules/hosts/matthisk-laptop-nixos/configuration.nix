{ inputs, ... }:
{
  flake.modules.nixos.matthisk-laptop-nixos = {
    imports = with inputs.self.modules.nixos; [
      disko
      homeManager
    ];

    networking.hostName = "matthisk-laptop-nixos";
    system.stateVersion = "25.11";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
