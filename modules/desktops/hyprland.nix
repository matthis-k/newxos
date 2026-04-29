{ inputs, withSystem, ... }:
{
  flake-file.inputs.hyprland = {
    url = "github:hyprwm/Hyprland";
  };

  flake.modules.nixos.hyprland =
    { pkgs, ... }:
    let
      hyprlandPackages = withSystem pkgs.stdenv.hostPlatform.system (
        { inputs', ... }: inputs'.hyprland.packages
      );
    in
    {
      environment.systemPackages = with pkgs; [
        brightnessctl
        hyprpolkitagent
        playerctl
        wl-clipboard
        wireplumber
      ];

      environment.variables = {
        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };

      nix.settings.substituters = [
        "https://hyprland.cachix.org"
      ];
      nix.settings.trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      programs.hyprland = {
        enable = true;
        package = hyprlandPackages.hyprland;
        portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
        withUWSM = true;
      };

      security.polkit.enable = true;

      services.dbus.enable = true;
      services.displayManager.defaultSession = "hyprland-uwsm";
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
      services.xserver.enable = true;

      xdg.portal.enable = true;

      systemd.user.services.hyprpolkitagent = {
        enable = true;
        description = "HyprPolkitAgent Service";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        };
      };
    };

  flake.modules.homeManager.hyprland =
    { ... }:
    {
      xdg.configFile."hypr" = {
        source = ../../configs/hypr;
        recursive = true;
      };

      xdg.configFile."hypr/nix-import.lua".text = ''
        return {}
      '';
    };
}
