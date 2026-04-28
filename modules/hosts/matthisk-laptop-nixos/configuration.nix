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
      audio
      disko
      homeManager
      hyprland
      locales
      networking
      nix
      nordvpn
      security
      sops
    ];

    networking.hostName = "matthisk-laptop-nixos";
    services.displayManager.autoLogin.user = "matthisk";
    system.stateVersion = "25.11";
  };
}
