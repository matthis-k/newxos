{ inputs, ... }:
{
  flake.modules.nixos.matthisk-laptop-newxos = {
    imports = with inputs.self.modules.nixos; [
      matthisk
    ];

    home-manager.users.matthisk.imports = [
      inputs.self.modules.homeManager.matthisk
    ];
  };
}
