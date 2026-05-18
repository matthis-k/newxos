{ inputs, ... }:
{
  flake.modules.nixos.common-workstation = {
    imports = with inputs.self.modules.nixos; [
      audio
      disko
      homeManager
      hyprland
      locales
      networking
      nix
      newxos
      security
      sops
      stylix
    ];
  };
}
