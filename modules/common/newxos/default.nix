{ withSystem, ... }:
{
  flake.modules.nixos.newxos =
    { config, pkgs, ... }:
    {
      boot.zfs.forceImportRoot = false;

      environment.sessionVariables.NEWXOS_HOST = config.networking.hostName;

      environment.systemPackages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: [ self'.packages.newxos ]
      );
    };

  flake.modules.homeManager.newxos =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }: [ self'.packages.newxos ]
      );

      home.sessionVariables.NEWXOS_FLAKE = "${config.home.homeDirectory}/newxos";
    };
}
