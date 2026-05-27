{ lib, ... }:
{
  flake.modules.nixos.devSpecialization =
    { config, ... }:
    {
      options.newxos.devMode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to use live configs for development.";
      };

      config = {
        environment.sessionVariables = lib.mkIf config.newxos.devMode {
          NEWXOS_DEV = "1";
        };

        specialisation.dev = {
          inheritParentConfig = true;
          configuration = {
            newxos.devMode = true;
          };
        };
      };
    };
}
