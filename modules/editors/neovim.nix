{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake-file.inputs.pick-resession-nvim = {
    url = "github:scottmckendry/pick-resession.nvim";
    flake = false;
  };

  flake-file.inputs.blink-lib = {
    url = "github:saghen/blink.lib";
    flake = false;
  };

  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      pluginSpecs = [
        {
          name = "lz.n";
          attr = "lz-n";
          src = "https://github.com/nvim-neorocks/lz.n";
        }
        {
          name = "base16-nvim";
          attr = "base16-nvim";
          src = "https://github.com/RRethy/base16-nvim";
        }
        {
          name = "which-key.nvim";
          attr = "which-key-nvim";
          src = "https://github.com/folke/which-key.nvim";
        }
        {
          name = "nvim-web-devicons";
          attr = "nvim-web-devicons";
          src = "https://github.com/nvim-tree/nvim-web-devicons";
        }
        {
          name = "nui.nvim";
          attr = "nui-nvim";
          src = "https://github.com/MunifTanjim/nui.nvim";
        }
        {
          name = "snacks.nvim";
          attr = "snacks-nvim";
          src = "https://github.com/folke/snacks.nvim";
        }
        {
          name = "resession.nvim";
          attr = "resession-nvim";
          src = "https://github.com/stevearc/resession.nvim";
        }
        {
          name = "pick-resession-nvim";
          input = "pick-resession-nvim";
          src = "https://github.com/scottmckendry/pick-resession.nvim";
        }
        {
          name = "nvim-lspconfig";
          attr = "nvim-lspconfig";
          src = "https://github.com/neovim/nvim-lspconfig";
        }
        {
          name = "nvim-treesitter";
          attr = "nvim-treesitter";
          src = "https://github.com/nvim-treesitter/nvim-treesitter";
        }
        {
          name = "conform.nvim";
          attr = "conform-nvim";
          src = "https://github.com/stevearc/conform.nvim";
        }
        {
          name = "lazydev.nvim";
          attr = "lazydev-nvim";
          src = "https://github.com/folke/lazydev.nvim";
        }
        {
          name = "markview.nvim";
          attr = "markview-nvim";
          src = "https://github.com/OXY2DEV/markview.nvim";
        }
        {
          name = "helpview.nvim";
          attr = "helpview-nvim";
          src = "https://github.com/OXY2DEV/helpview.nvim";
        }
        {
          name = "gitsigns.nvim";
          attr = "gitsigns-nvim";
          src = "https://github.com/lewis6991/gitsigns.nvim";
        }
        {
          name = "blink.lib";
          input = "blink-lib";
          src = "https://github.com/saghen/blink.lib";
        }
        {
          name = "blink.cmp";
          attr = "blink-cmp";
          src = "https://github.com/saghen/blink.cmp";
        }
        {
          name = "opencode.nvim";
          attr = "opencode-nvim";
          src = "https://github.com/nickjvandyke/opencode.nvim";
        }
        {
          name = "telescope.nvim";
          attr = "telescope-nvim";
          src = "https://github.com/nvim-telescope/telescope.nvim";
        }
      ];
      pluginPackage =
        plugin:
        if plugin ? attr then
          if plugin.attr == "nvim-treesitter" then
            pkgs.vimPlugins.nvim-treesitter.withAllGrammars
          else
            builtins.getAttr plugin.attr pkgs.vimPlugins
        else if plugin ? input then
          pkgs.vimUtils.buildVimPlugin {
            pname = plugin.name;
            version = "unstable";
            src = builtins.getAttr plugin.input inputs;
          }
        else
          throw "Unsupported Neovim plugin manifest entry: ${plugin.name}";
      sourceRevisionFromUrl =
        url:
        let
          baseName = builtins.baseNameOf url;
          matches = builtins.match "(.+)\\.(tar\\.gz|tar\\.xz|tgz|zip)$" baseName;
        in
        if matches == null then
          throw "Could not infer plugin revision from URL: ${url}"
        else
          builtins.elemAt matches 0;
      pluginRevision =
        plugin:
        let
          src =
            if plugin ? input then
              builtins.getAttr plugin.input inputs
            else if plugin.attr == "nvim-treesitter" then
              pkgs.vimPlugins.nvim-treesitter.src
            else
              (pluginPackage plugin).src;
        in
        if src ? rev then
          src.rev
        else if src ? url then
          sourceRevisionFromUrl src.url
        else
          throw "Could not determine plugin revision for ${plugin.name}";
      pluginManifest = map (plugin: plugin // { rev = pluginRevision plugin; }) pluginSpecs;
      pluginLockFile = pkgs.writeText "nvim-pack-lock.json" (
        builtins.toJSON {
          plugins = builtins.listToAttrs (
            map (plugin: {
              name = plugin.name;
              value = {
                rev = plugin.rev;
                src = plugin.src;
              };
            }) pluginManifest
          );
        }
      );
      commonConfig =
        {
          pkgs,
          configDirectory,
          binName ? "nvim",
          aliases ? [ ],
          dontLink ? false,
        }:
        inputs.nix-wrapper-modules.wrappers.neovim.wrap {
          inherit binName pkgs;

          settings = {
            inherit aliases;
            config_directory = configDirectory;
            dont_link = dontLink;
            nvim_lua_env = lp: [
              lp.magick
              lp.luautf8
            ];
            use_nix_managed_plugins = true;
          };

          hosts = {
            python3.nvim-host.enable = true;
            node.nvim-host.enable = true;
            ruby.nvim-host.enable = true;
            perl.nvim-host.enable = true;
          };

          extraPackages =
            with pkgs;
            [
              curl
              self'.packages.dev-tools
              fd
              fzf
              gh
              git
              imagemagick
              lsof
            ]
            ++ lib.optional (self'.packages ? opencode) self'.packages.opencode;

          specs.plugins.data = map pluginPackage pluginManifest;
        };
    in
    {
      packages = rec {
        nvim = commonConfig {
          inherit pkgs;
          aliases = [
            "vi"
            "vim"
          ];
          configDirectory = ../../configs/nvim;
        };

        nvimdev = commonConfig {
          inherit pkgs;
          aliases = [ "nvd" ];
          binName = "nvimdev";
          configDirectory = lib.generators.mkLuaInline (builtins.toJSON (toString ../../configs/nvim));
          dontLink = true;
        };

        default = nvim;

        write-nvim-pack-lock = pkgs.writeShellScriptBin "write-nvim-pack-lock" ''
          set -euo pipefail

          install -m 0644 ${pluginLockFile} "$PWD/configs/nvim/nvim-pack-lock.json"
        '';
      };
    };

  flake.modules.homeManager.neovim =
    { pkgs, ... }:
    {
      home.packages = withSystem pkgs.stdenv.hostPlatform.system (
        { self', ... }:
        [
          self'.packages.nvim
          self'.packages.nvimdev
        ]
      );

      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
}
