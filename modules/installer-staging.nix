{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  mkStagingModule =
    hostName: cfg:
    { lib, ... }:
    {
      imports = [
        inputs.self.modules.nixos.${cfg.baseModule}
      ]
      ++ (with inputs.self.modules.nixos; [
        disko
        locales
        networking
        newxos
        nix
      ])
      ++ cfg.extraModules;

      networking.hostName = hostName;
      environment.sessionVariables.NEWXOS_FLAKE = "/home/${cfg.user}/newxos";
      system.nixos.tags = [ "staging" ];
      system.stateVersion = cfg.stateVersion;

      boot.plymouth.enable = lib.mkForce false;
    };
in
{
  options.newxos.installer.stagingHosts = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to generate a low-memory staging installer host.";
            };

            baseModule = mkOption {
              type = types.str;
              default = "${name}-base";
              description = "NixOS module name containing host-local boot, storage, swap, and minimal user wiring.";
            };

            hostPlatform = mkOption {
              type = types.str;
              default = "x86_64-linux";
              description = "Platform for the generated staging NixOS system.";
            };

            user = mkOption {
              type = types.str;
              description = "User that should be able to log in and run newxos os switch after first boot.";
            };

            stateVersion = mkOption {
              type = types.str;
              default = "25.11";
              description = "NixOS stateVersion for the generated staging host.";
            };

            extraModules = mkOption {
              type = types.listOf types.deferredModule;
              default = [ ];
              description = "Extra NixOS modules to include in the generated staging host.";
            };
          };
        }
      )
    );
    default = { };
    description = "Hosts that should get generated <host>-staging outputs for low-memory USB installs.";
  };

  config.flake =
    let
      enabledStagingHosts = lib.filterAttrs (_: cfg: cfg.enable) config.newxos.installer.stagingHosts;
    in
    {
      nixosConfigurations = lib.mapAttrs' (
        hostName: cfg:
        lib.nameValuePair "${hostName}-staging" (
          inputs.nixpkgs.lib.nixosSystem {
            modules = [
              (mkStagingModule hostName cfg)
              { nixpkgs.hostPlatform = cfg.hostPlatform; }
            ];
          }
        )
      ) enabledStagingHosts;

      newxosInstallerStagingHosts = lib.mapAttrs (_: cfg: { inherit (cfg) user; }) enabledStagingHosts;
    };
}
