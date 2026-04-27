{ inputs, ... }:
{
  flake.nixosConfigurations.matthisk-laptop-nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.modules.nixos.matthisk-laptop-nixos
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };

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
