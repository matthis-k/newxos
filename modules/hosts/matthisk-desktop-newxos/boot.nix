_:
let
  bootConfig =
    { pkgs, ... }:
    {
      boot.initrd.systemd.enable = true;
      boot.plymouth = {
        enable = true;
        font = "${pkgs.nerd-fonts.hack}/share/fonts/truetype/NerdFonts/Hack/HackNerdFontMono-Regular.ttf";
      };

      boot.loader = {
        efi.canTouchEfiVariables = true;
        grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
          useOSProber = true;
        };
      };
    };
in
{
  flake.modules.nixos.matthisk-desktop-newxos = bootConfig;
}
