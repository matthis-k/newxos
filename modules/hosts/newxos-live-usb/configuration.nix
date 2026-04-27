{ inputs, ... }:
{
  flake.nixosConfigurations.newxos-live-usb = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.modules.nixos.newxos-live-usb
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };

  flake.modules.nixos.newxos-live-usb = {
    imports = [
      (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
    ]
    ++ (with inputs.self.modules.nixos; [
      installerMedia
      locales
      networking
      nix
    ]);

    networking.hostName = "newxos-live-usb";
    system.stateVersion = "25.11";

    isoImage.configurationName = "newxos live usb";
  };
}
