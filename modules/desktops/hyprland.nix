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

      screenShotBin = pkgs.writeShellScriptBin "screen-shot" ''
        set -euo pipefail

        mode="''${1:-region}"
        screenshots_dir="''${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"

        ${pkgs.coreutils}/bin/mkdir -p "$screenshots_dir"

        case "$mode" in
          region)
            output_file="$screenshots_dir/screen-shot-region-$(date +%Y%m%d-%H%M%S).png"
            ${pkgs.grimblast}/bin/grimblast --freeze --filetype ppm save area - | ${pkgs.satty}/bin/satty \
              --filename - \
              --fullscreen \
              --output-filename "$output_file"
            ;;
          region-direct)
            output_file="$screenshots_dir/screen-shot-region-$(date +%Y%m%d-%H%M%S).png"
            ${pkgs.grimblast}/bin/grimblast --notify --freeze copysave area "$output_file"
            ;;
          output)
            output_file="$screenshots_dir/screen-shot-output-$(date +%Y%m%d-%H%M%S).png"
            ${pkgs.grimblast}/bin/grimblast --filetype ppm save output - | ${pkgs.satty}/bin/satty \
              --filename - \
              --fullscreen \
              --output-filename "$output_file"
            ;;
          window)
            output_file="$screenshots_dir/screen-shot-window-$(date +%Y%m%d-%H%M%S).png"
            ${pkgs.grimblast}/bin/grimblast --filetype ppm save active - | ${pkgs.satty}/bin/satty \
              --filename - \
              --fullscreen \
              --output-filename "$output_file"
            ;;
          *)
            printf 'usage: screen-shot [region|region-direct|output|window]\n' >&2
            exit 2
            ;;
        esac
      '';

      screenShotCompletion = pkgs.writeTextDir "share/fish/vendor_completions.d/screen-shot.fish" ''
        complete -c screen-shot -f
        complete -c screen-shot -n 'not __fish_seen_subcommand_from region region-direct output window' -a 'region region-direct output window'
      '';

      screenShot = pkgs.symlinkJoin {
        name = "screen-shot";
        paths = [
          screenShotBin
          screenShotCompletion
        ];
      };

      screenReadRegion = pkgs.writeShellScriptBin "screen-read-region" ''
        set -euo pipefail

        tmp_png="$(${pkgs.coreutils}/bin/mktemp --suffix .png)"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp_png"' EXIT

        ${pkgs.grimblast}/bin/grimblast --freeze save area - > "$tmp_png"

        text="$(${pkgs.tesseract}/bin/tesseract "$tmp_png" stdout -l ''${OCR_LANG:-eng} 2>/dev/null | ${pkgs.gnused}/bin/sed '/^[[:space:]]*$/d')"

        if [ -z "$text" ]; then
          ${pkgs.libnotify}/bin/notify-send "Screen OCR" "No text detected"
          exit 1
        fi

        printf '%s' "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
        printf '%s\n' "$text"
        ${pkgs.libnotify}/bin/notify-send "Screen OCR" "Copied text to clipboard"
      '';

      screenEditClipboard = pkgs.writeShellScriptBin "screen-edit-clipboard" ''
        set -euo pipefail

        screenshots_dir="''${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
        output_file="$screenshots_dir/screen-edit-$(date +%Y%m%d-%H%M%S).png"
        image_type=""

        ${pkgs.coreutils}/bin/mkdir -p "$screenshots_dir"

        while IFS= read -r candidate; do
          case "$candidate" in
            image/*)
              image_type="$candidate"
              break
              ;;
          esac
        done <<EOF
        $(${pkgs.wl-clipboard}/bin/wl-paste --list-types 2>/dev/null || true)
        EOF

        if [ -z "$image_type" ]; then
          ${pkgs.libnotify}/bin/notify-send "Satty" "Clipboard has no image"
          exit 1
        fi

        ${pkgs.wl-clipboard}/bin/wl-paste --type "$image_type" | ${pkgs.satty}/bin/satty \
          --filename - \
          --fullscreen \
          --output-filename "$output_file"
      '';
    in
    {
      environment.systemPackages = with pkgs; [
        brightnessctl
        grimblast
        hyprpolkitagent
        libnotify
        playerctl
        satty
        tesseract
        wl-clipboard
        wireplumber
        screenShot
        screenReadRegion
        screenEditClipboard
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

      xdg.configFile."satty/config.toml".text = ''
        [general]
        copy-command = "wl-copy"
        corner-roundness = 10
        early-exit = true
        fullscreen = true
        initial-tool = "arrow"
        actions-on-enter = ["save-to-clipboard", "save-to-file", "exit"]
        actions-on-escape = ["exit"]
        actions-on-right-click = ["save-to-clipboard", "save-to-file", "exit"]
      '';
    };
}
