{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake.modules.nixos.wayland-tools =
    {
      config,
      options,
      pkgs,
      ...
    }:
    let
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

      readImage = pkgs.writeShellScriptBin "read-image" ''
        set -euo pipefail

        if [ ''${1:-} = "--clipboard" ]; then
          shift
          img_type="$(${pkgs.wl-clipboard}/bin/wl-paste --list-types 2>/dev/null | ${pkgs.gnugrep}/bin/grep '^image/' | ${pkgs.coreutils}/bin/head -1)"
          if [ -z "$img_type" ]; then
            ${pkgs.libnotify}/bin/notify-send "read-image" "Clipboard has no image"
            exit 1
          fi
          ${pkgs.wl-clipboard}/bin/wl-paste --type "$img_type" | "$0" "$@"
          exit
        fi

        tmp="$(${pkgs.coreutils}/bin/mktemp --suffix .png)"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

        ${pkgs.coreutils}/bin/cat > "$tmp"

        text="$(${pkgs.tesseract}/bin/tesseract "$tmp" stdout -l ''${OCR_LANG:-eng} 2>/dev/null | ${pkgs.gnused}/bin/sed '/^[[:space:]]*$/d')"

        if [ -z "$text" ]; then
          ${pkgs.libnotify}/bin/notify-send "read-image" "No text detected"
          exit 1
        fi

        printf '%s\n' "$text"
      '';

      annotate = pkgs.writeShellScriptBin "annotate" ''
        set -euo pipefail

        if [ ''${1:-} = "--clipboard" ]; then
          shift
          img_type="$(${pkgs.wl-clipboard}/bin/wl-paste --list-types 2>/dev/null | ${pkgs.gnugrep}/bin/grep '^image/' | ${pkgs.coreutils}/bin/head -1)"
          if [ -z "$img_type" ]; then
            ${pkgs.libnotify}/bin/notify-send "annotate" "Clipboard has no image"
            exit 1
          fi
          ${pkgs.wl-clipboard}/bin/wl-paste --type "$img_type" | "$0" "$@"
          exit
        fi

        screenshots_dir="''${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
        output_file="$screenshots_dir/annotate-$(date +%Y%m%d-%H%M%S).png"

        ${pkgs.coreutils}/bin/mkdir -p "$screenshots_dir"

        ${pkgs.coreutils}/bin/cat | ${pkgs.satty}/bin/satty \
          --filename - \
          --fullscreen \
          --output-filename "$output_file"
      '';
    in
    {
      config = {
        environment.systemPackages = with pkgs; [
          grimblast
          libnotify
          satty
          tesseract
          wl-clipboard
          screenShot
          screenReadRegion
          screenEditClipboard
          readImage
          annotate
        ];
      };
    };

  flake.modules.homeManager.wayland-tools = _: {
    config = {
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
  };
}
