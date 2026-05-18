{
  inputs,
  lib,
  ...
}:
let
  configDir = builtins.path {
    name = "hyprland-config";
    path = ../../../configs/hypr;
  };

  luaValueType = lib.types.oneOf [
    lib.types.bool
    lib.types.int
    lib.types.float
    lib.types.str
    (lib.types.listOf luaValueType)
    (lib.types.attrsOf luaValueType)
  ];

  toLua =
    value:
    if lib.isAttrs value then
      "{ "
      + lib.concatStringsSep ", " (
        lib.mapAttrsToList (name: attrValue: "[${builtins.toJSON name}] = ${toLua attrValue}") value
      )
      + " }"
    else if lib.isList value then
      "{ " + lib.concatMapStringsSep ", " toLua value + " }"
    else
      builtins.toJSON value;

  hyprland = inputs.nix-wrapper-modules.lib.wrapModule (
    {
      config,
      lib,
      pkgs,
      wlib,
      ...
    }:
    let
      luaContent = toLua config.luaVariables;

      nixImportLua = pkgs.writeText "nix-import.lua" ''
        return ${luaContent}
      '';

      usesDefaultConfig = config.configDirectory == "~/.config/hypr";

      mergedConfigDir =
        if usesDefaultConfig then
          null
        else
          pkgs.runCommand "hyprland-merged-config" { } ''
            cp -r --no-preserve=mode,ownership ${config.configDirectory} "$out"
            chmod -R u+w "$out"
            cp ${nixImportLua} "$out/nix-import.lua"
          '';

      configFlag =
        if usesDefaultConfig then "~/.config/hypr/hyprland.lua" else "${mergedConfigDir}/hyprland.lua";
    in
    {
      options.configDirectory = lib.mkOption {
        type = wlib.types.stringable;
        default = "~/.config/hypr";
        description = "Hyprland config directory containing hyprland.lua.";
      };

      options.luaVariables = lib.mkOption {
        type = luaValueType;
        default = { };
        description = "Arbitrary Lua variables serialized to nix-import.lua.";
      };

      config = {
        binName = "Hyprland";
        flags."--config" = configFlag;
        meta.description = "Wrapped Hyprland compositor with newxos config.";
        passthru.providedSessions = [ "hyprland-uwsm" ];
      };
    }
  );
in
{
  flake.lib.wrapper-modules.hyprland = hyprland;

  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    {
      packages.hyprland = inputs'.hyprland.packages.hyprland;

      packages.newxos-hyprland = hyprland.wrap {
        inherit pkgs;
        configDirectory = configDir;
        package = inputs'.hyprland.packages.hyprland;
        luaVariables = {
          monitors = [ { output = "auto"; } ];
        };
      };
    };
}
