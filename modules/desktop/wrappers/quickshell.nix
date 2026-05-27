_:
let
  configDir = builtins.path {
    name = "quickshell-config";
    path = ../../../configs/quickshell;
    filter = path: type: !(type == "regular" && builtins.baseNameOf path == ".qmlls.ini");
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.quickshell = pkgs.quickshell;

      packages.newshell = pkgs.writeShellApplication {
        name = "newshell";
        runtimeInputs = [ pkgs.quickshell ];
        text = ''
          config_dir=${configDir}
          if [ "''${NEWXOS_DEV:-0}" = 1 ]; then
            config_dir="''${NEWXOS_FLAKE:-$HOME/newxos}/configs/quickshell"
          fi

          exec quickshell -p "$config_dir" "$@"
        '';
      };
    };
}
