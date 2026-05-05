{ inputs, withSystem, ... }:
{
  flake-file.inputs.firefox-addons = {
    url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.zen-flake = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  flake.modules.homeManager.zen-browser =
    { pkgs, ... }:
    let
      zenPackage = withSystem pkgs.stdenv.hostPlatform.system (
        { inputs', ... }: inputs'.zen-flake.packages.beta
      );
      firefoxAddons = withSystem pkgs.stdenv.hostPlatform.system (
        { inputs', ... }: inputs'.firefox-addons.packages
      );
      nixSnowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      duckduckgoNewTab = "https://duckduckgo.com/";
    in
    {
      imports = [ inputs.zen-flake.homeModules.beta ];

      programs.zen-browser = {
        enable = true;
        package = zenPackage;
        setAsDefaultBrowser = true;

        policies = {
          AppAutoUpdate = false;
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          BackgroundAppUpdate = false;
          Certificates.ImportEnterpriseRoots = true;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxAccounts = false;
          DisableFirefoxScreenshots = false;
          DisableFirefoxStudies = true;
          DisableMasterPasswordCreation = true;
          DisablePasswordReveal = true;
          DisablePocket = true;
          DisableProfileImport = true;
          DisableProfileRefresh = true;
          DisableSetDesktopBackground = true;
          DisableSystemAddonUpdate = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          DNSOverHTTPS = {
            Enabled = true;
            ProviderURL = "https://cloudflare-dns.com/dns-query";
            Fallback = true;
          };
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          HTTPSOnlyMode = {
            Value = true;
          };
          NoDefaultBookmarks = false;
          NewTabPage = {
            URL = duckduckgoNewTab;
            Locked = true;
          };
          OfferToSaveLogins = false;
          OverrideFirstRunPage = duckduckgoNewTab;
          OverridePostUpdatePage = "";
          PasswordManagerEnabled = false;
          Preferences = {
            "browser.contentblocking.category" = "strict";
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.search.suggest.enabled" = false;
            "browser.search.suggest.enabled.private" = false;
            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "extensions.htmlaboutaddons.recommendations.enabled" = false;
            "extensions.pocket.enabled" = false;
            "extensions.screenshots.disabled" = true;
            "privacy.query_stripping.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.pbmode.enabled" = true;
          };
          PromptForDownloadLocation = true;
          SearchBar = "unified";
          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
          };
        };

        profiles.default = {
          search = {
            force = true;
            default = "ddg";
            privateDefault = "ddg";
            engines = {
              "My NixOS" = {
                urls = [
                  {
                    template = "https://mynixos.com/search?q={searchTerms}";
                  }
                ];
                icon = nixSnowflake;
                definedAliases = [ "@nx" ];
              };
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
                  }
                ];
                icon = nixSnowflake;
                definedAliases = [
                  "@np"
                  "@pkg"
                  "@pkgs"
                ];
              };
              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
                  }
                ];
                icon = nixSnowflake;
                definedAliases = [
                  "@no"
                  "@opt"
                ];
              };
              ChatGPT = {
                urls = [
                  {
                    template = "https://chat.openai.com";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "https://chatgpt.com/cdn/assets/favicon-eex17e9e.ico";
                definedAliases = [
                  "@gpt"
                  "@ai"
                  "@chatgpt"
                ];
              };
            };
          };

          bookmarks = {
            force = true;
            settings = [
              {
                name = "Nix resources";
                toolbar = true;
                bookmarks = [
                  {
                    name = "NixOS packages";
                    url = "https://search.nixos.org/packages";
                  }
                  {
                    name = "NixOS options";
                    url = "https://search.nixos.org/options";
                  }
                  {
                    name = "Home Manager options";
                    url = "https://home-manager-options.extranix.com";
                  }
                ];
              }
            ];
          };

          extensions.packages = with firefoxAddons; [
            ublock-origin
            privacy-badger
            duckduckgo-privacy-essentials
            bitwarden
            catppuccin-web-file-icons
          ];

          settings = {
            "browser.startup.homepage" = duckduckgoNewTab;
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.tabs.warnOnClose" = false;
            "browser.warnOnQuitShortcut" = false;
            "browser.compactmode.show" = true;
            "browser.download.useDownloadDir" = false;
            "browser.urlbar.showFullURL" = true;
            "browser.urlbar.trimURLs" = false;
            "extensions.pocket.enabled" = false;
            "general.autoScroll" = true;
            "media.ffmpeg.vaapi.enabled" = true;
            "network.trr.mode" = 2;
            "privacy.donottrackheader.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.pbmode.enabled" = true;
            "signon.rememberSignons" = false;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "zen.urlbar.behavior" = "normal";
          };
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/json" = [ "nvim.desktop" ];
          "image/gif" = [ "zen-beta.desktop" ];
          "image/jpeg" = [ "zen-beta.desktop" ];
          "image/png" = [ "zen-beta.desktop" ];
          "image/svg+xml" = [ "zen-beta.desktop" ];
          "image/webp" = [ "zen-beta.desktop" ];
          "text/markdown" = [ "nvim.desktop" ];
          "text/plain" = [ "nvim.desktop" ];
        };
      };

      stylix.targets.zen-browser.profileNames = [ "default" ];

      home.sessionVariables.BROWSER = "zen-beta";
    };
}
