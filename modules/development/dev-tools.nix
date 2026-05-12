{
  lib,
  withSystem,
  ...
}:
let
  availableLanguages = [
    "c"
    "cpp"
    "css"
    "json"
    "markdown"
    "toml"
    "ts"
    "rust"
    "python"
    "lua"
    "nix"
    "xml"
    "qml"
  ];

  defaultLanguages = availableLanguages;

  mkCommonTools =
    pkgs: with pkgs; [
      curl
      fd
      jq
      ripgrep
    ];

  mkToolsets =
    pkgs:
    let
      cFamily = with pkgs; [
        bear
        clang
        clang-tools
        cmake
        gdb
        gnumake
        pkg-config
      ];

      vscodeWebLs = with pkgs; [
        vscode-langservers-extracted
      ];
    in
    {
      c = cFamily;
      cpp = cFamily;

      css = vscodeWebLs;

      json = vscodeWebLs;

      markdown = with pkgs; [
        marksman
      ];

      toml = with pkgs; [
        taplo
      ];

      ts = with pkgs; [
        nodejs
        typescript
        typescript-language-server
        vscode-langservers-extracted
      ];

      rust = with pkgs; [
        cargo
        rust-analyzer
        rustc
      ];

      python = with pkgs; [
        pyright
        python3
        ruff
        uv
      ];

      lua = with pkgs; [
        lua-language-server
        lua5_1
        luarocks
        stylua
      ];

      nix = with pkgs; [
        deadnix
        nil
        nixd
        nixfmt
        statix
      ];

      xml = with pkgs; [
        lemminx
      ];

      qml = with pkgs; [
        kdePackages.qtdeclarative
      ];
    };

  mkDevTools =
    pkgs:
    {
      languages ? defaultLanguages,
    }:
    let
      selectedLanguages = lib.unique languages;
      toolsets = mkToolsets pkgs;
      invalidLanguages = builtins.filter (
        language: !(builtins.hasAttr language toolsets)
      ) selectedLanguages;
      nameSuffix = lib.optionalString (
        selectedLanguages != defaultLanguages
      ) "-${lib.concatStringsSep "-" selectedLanguages}";
    in
    assert lib.assertMsg (
      invalidLanguages == [ ]
    ) "Unknown dev-tools languages: ${lib.concatStringsSep ", " invalidLanguages}";
    pkgs.buildEnv {
      name = "dev-tools${nameSuffix}";
      paths = lib.unique (
        (mkCommonTools pkgs)
        ++ lib.flatten (map (language: builtins.getAttr language toolsets) selectedLanguages)
      );
    };

  mkDevToolsForSystem = system: args: withSystem system ({ pkgs, ... }: mkDevTools pkgs args);
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.dev-tools = mkDevTools pkgs { };
    };

  flake.lib.devTools = {
    inherit availableLanguages defaultLanguages;
    mkPackage = mkDevToolsForSystem;
  };

  flake.modules.homeManager.dev-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.newxos.devTools;
    in
    {
      options.newxos.devTools = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to install repo dev-tools package.";
        };

        languages = lib.mkOption {
          type = lib.types.listOf (lib.types.enum availableLanguages);
          default = defaultLanguages;
          example = [
            "rust"
            "lua"
          ];
          description = "Language toolsets to include in dev-tools package.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          (mkDevToolsForSystem pkgs.stdenv.hostPlatform.system { inherit (cfg) languages; })
        ];
      };
    };
}
