_:
let
  configDir = builtins.path {
    name = "newshell-config";
    path = ../../../configs/newshell;
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
          quickshell_args=()
          if [ "''${NEWXOS_DEV:-0}" = 1 ]; then
            config_dir="''${NEWXOS_FLAKE:-$HOME/newxos}/configs/newshell"
            quickshell_args+=(--verbose)
          fi

          exec quickshell -p "$config_dir" "''${quickshell_args[@]}" "$@"
        '';
      };
    };
}
