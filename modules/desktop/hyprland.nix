{
  inputs,
  lib,
  withSystem,
  ...
}:
let
  hyprlandWrapper = inputs.self.lib.wrapper-modules.hyprland;

  configDir = builtins.path {
    name = "hyprland-config";
    path = ../../configs/hypr;
  };
in
{
  flake-file.inputs.hyprland = {
    url = "github:hyprwm/Hyprland";
  };

  flake.modules.nixos.hyprland =
    {
      config,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.newxos.hyprland;

      hyprlandPackages = withSystem pkgs.stdenv.hostPlatform.system (
        { inputs', ... }: inputs'.hyprland.packages
      );

      wrappedPackage = withSystem pkgs.stdenv.hostPlatform.system (
        { inputs', ... }:
        hyprlandWrapper.wrap {
          pkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          configDirectory = configDir;
          package = inputs'.hyprland.packages.hyprland;
          luaVariables = {
            inherit (cfg) monitors;
          };
        }
      );

      hyprctlFishCompletion = pkgs.runCommand "hyprctl-fish-completion" { } ''
        mkdir -p hyprctl $out/share/fish/vendor_completions.d
        cp ${hyprlandPackages.hyprland}/share/fish/vendor_completions.d/hyprctl.fish hyprctl/hyprctl.fish
        chmod u+w hyprctl/hyprctl.fish
        patch -p1 < ${../../patches/hyprctl-fish-completions.patch}
        cp hyprctl/hyprctl.fish $out/share/fish/vendor_completions.d/hyprctl.fish
      '';
    in
    {
      options.newxos.hyprland = {
        monitors = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.listOf (
              lib.types.submodule {
                options = {
                  output = lib.mkOption {
                    type = lib.types.str;
                    description = "Output name.";
                  };
                  mode = lib.mkOption {
                    type = lib.types.str;
                    default = "preferred";
                    description = "Output mode resolution.";
                  };
                  position = lib.mkOption {
                    type = lib.types.str;
                    default = "auto";
                    description = "Output position.";
                  };
                  scale = lib.mkOption {
                    type = lib.types.number;
                    default = 1;
                    description = "Output scale factor.";
                  };
                };
              }
            )
          );
          default = null;
          description = "Monitor list for the wrapped Hyprland package. Null disables the wrapper.";
        };

        enableRuntimeLuaImport = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Copy nix-import.lua to /run/newxos/hypr on activation for live reload.";
        };
      };

      config = {
        environment.systemPackages =
          with pkgs;
          [
            brightnessctl
            hyprpolkitagent
            (lib.hiPrio hyprctlFishCompletion)
            playerctl
            wireplumber
          ]
          ++ lib.optional (cfg.monitors != null) wrappedPackage;

        environment.variables = {
          QT_QPA_PLATFORM = "wayland";
          SDL_VIDEODRIVER = "wayland";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        };

        nix.settings = {
          substituters = [ "https://hyprland.cachix.org" ];
          trusted-substituters = [ "https://hyprland.cachix.org" ];
          trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
        };

        programs.hyprland = {
          enable = true;
          package = lib.mkDefault (
            if cfg.monitors != null then wrappedPackage else hyprlandPackages.hyprland
          );
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

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        systemd.user.services.hyprpolkitagent = {
          enable = true;
          description = "HyprPolkitAgent Service";
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
          };
        };

        system.activationScripts.hyprland-nix-import = lib.mkIf cfg.enableRuntimeLuaImport (
          lib.stringAfter [ "etc" ] ''
            mkdir -p /run/newxos/hypr
            cp -f ${wrappedPackage.passthru.nixImportLua} /run/newxos/hypr/nix-import.lua
          ''
        );
      };
    };

  flake.modules.homeManager.hyprland = _: {
    config = { };
  };
}
