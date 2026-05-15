{ inputs, ... }:
let
  configDir = builtins.path {
    name = "quickshell-config";
    path = ../../configs/quickshell;
    filter = path: type: !(type == "regular" && builtins.baseNameOf path == ".qmlls.ini");
  };

  quickshellWrapper = inputs.nix-wrapper-modules.lib.wrapModule (
    {
      config,
      lib,
      pkgs,
      wlib,
      ...
    }:
    {
      options.configDirectory = lib.mkOption {
        type = wlib.types.stringable;
        description = "QuickShell config directory passed to quickshell -p.";
      };

      config = {
        package = pkgs.quickshell;
        flags."-p" = config.configDirectory;
        meta.description = "Wrapped QuickShell launcher for the newxos shell config.";
      };
    }
  );
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.quickshell = pkgs.quickshell;

      packages.newshell = quickshellWrapper.wrap {
        inherit pkgs;
        binName = "newshell";
        configDirectory = configDir;
      };

      packages.newshelldev = quickshellWrapper.wrap {
        inherit pkgs;
        binName = "newshelldev";
        configDirectory = "\${NEWXOS_FLAKE:-$HOME/newxos}/configs/quickshell";
        escapingFunction = inputs.nix-wrapper-modules.lib.escapeShellArgWithEnv;
      };
    };
}
