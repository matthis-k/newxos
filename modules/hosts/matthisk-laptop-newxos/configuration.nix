{ inputs, ... }:
{
  flake.nixosConfigurations.matthisk-laptop-newxos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.modules.nixos.matthisk-laptop-newxos
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };

  flake.modules.nixos.matthisk-laptop-newxos = {
    imports = with inputs.self.modules.nixos; [
      audio
      disko
      homeManager
      hyprland
      locales
      networking
      nix
      newxos
      nordvpn
      security
      sops
      stylix
    ];

    networking.hostName = "matthisk-laptop-newxos";
    services.displayManager.autoLogin.user = "matthisk";
    system.stateVersion = "25.11";
  };
}
