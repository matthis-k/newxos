{ lib, ... }:
{
  flake.modules.homeManager.stylix-zen-browser =
    {
      config,
      options,
      ...
    }:
    let
      fullPalette = config.stylix.fullPalette;
      c = fullPalette.colors;
      capitalize =
        value:
        let
          len = builtins.stringLength value;
        in
        if len == 0 then
          value
        else
          lib.toUpper (builtins.substring 0 1 value) + builtins.substring 1 (len - 1) value;
      accentName = "Blue";
      accentColor = c.blue;
      flavorName = capitalize fullPalette.flavor;
      logoUrl = "https://raw.githubusercontent.com/catppuccin/zen-browser/main/themes/${flavorName}/${accentName}/zen-logo-${fullPalette.flavor}.svg";
      profileNames = config.stylix.targets.zen-browser.profileNames;
      newTabButtonSelector = ":is(#tabs-newtab-button, #vertical-tabs-newtab-button)";
      tabForegroundSelectors = ''
        .tab-label,
        .tab-close-button,
        .tab-icon-overlay,
        .tab-sharing-icon-overlay
      '';
      identityColors = [
        {
          name = "blue";
          value = c.blue;
        }
        {
          name = "turquoise";
          value = c.teal;
        }
        {
          name = "green";
          value = c.green;
        }
        {
          name = "yellow";
          value = c.yellow;
        }
        {
          name = "orange";
          value = c.peach;
        }
        {
          name = "red";
          value = c.red;
        }
        {
          name = "pink";
          value = c.pink;
        }
        {
          name = "purple";
          value = c.mauve;
        }
      ];
      mkIdentityColorCss =
        { name, value }:
        ''
          .identity-color-${name} {
            --identity-tab-color: ${value} !important;
            --identity-icon-color: ${value} !important;
          }
        '';
      identityColorCss = builtins.concatStringsSep "\n" (map mkIdentityColorCss identityColors);

      userChrome = ''
                /* Generated from config.stylix.fullPalette. */
                /* Layout follows official catppuccin/zen-browser theme with repo-local fixes. */

                :root {
                    --ctp-rosewater: ${c.rosewater} !important;
                    --ctp-flamingo: ${c.flamingo} !important;
                    --ctp-pink: ${c.pink} !important;
                    --ctp-mauve: ${c.mauve} !important;
                    --ctp-red: ${c.red} !important;
                    --ctp-maroon: ${c.maroon} !important;
                    --ctp-peach: ${c.peach} !important;
                    --ctp-yellow: ${c.yellow} !important;
                    --ctp-green: ${c.green} !important;
                    --ctp-teal: ${c.teal} !important;
                    --ctp-sky: ${c.sky} !important;
                    --ctp-sapphire: ${c.sapphire} !important;
                    --ctp-blue: ${accentColor} !important;
                    --ctp-lavender: ${c.lavender} !important;
                    --ctp-text: ${c.text} !important;
                    --ctp-subtext1: ${c.subtext1} !important;
                    --ctp-subtext0: ${c.subtext0} !important;
                    --ctp-overlay2: ${c.overlay2} !important;
                    --ctp-overlay1: ${c.overlay1} !important;
                    --ctp-overlay0: ${c.overlay0} !important;
                    --ctp-surface2: ${c.surface2} !important;
                    --ctp-surface1: ${c.surface1} !important;
                    --ctp-surface0: ${c.surface0} !important;
                    --ctp-base: ${c.base} !important;
                    --ctp-mantle: ${c.mantle} !important;
                    --ctp-crust: ${c.crust} !important;

                    --zen-theme-accent: var(--ctp-blue) !important;
                    --zen-theme-toolbar-bg: var(--ctp-surface0) !important;
                    --zen-theme-toolbar-bg-alt: var(--ctp-mantle) !important;
                    --zen-theme-browser-bg: var(--ctp-mantle) !important;
                    --zen-theme-page-bg: var(--ctp-base) !important;
                    --zen-theme-sidebar-bg: var(--ctp-mantle) !important;
                    --zen-theme-panel-bg: var(--ctp-base) !important;
                    --zen-theme-text: var(--ctp-text) !important;
                    --zen-theme-selected-tab-fg: var(--zen-theme-accent) !important;
                    --zen-theme-selected-tab-bg: var(--zen-theme-toolbar-bg) !important;
                    --zen-theme-hover-bg: var(--zen-theme-toolbar-bg) !important;
                    --zen-theme-urlbar-hover-bg: var(--ctp-surface1) !important;
                    --zen-theme-urlbar-selected-bg: color-mix(in srgb, var(--zen-theme-accent) 14%, var(--ctp-surface1) 86%) !important;
                    --zen-theme-urlbar-selected-fg: var(--ctp-text) !important;
                    --zen-theme-urlbar-selected-muted: var(--ctp-subtext0) !important;
                    --zen-theme-urlbar-chip-bg: var(--ctp-surface2) !important;
                    color-scheme: dark !important;

                    --zen-colors-primary: var(--zen-theme-toolbar-bg) !important;
                    --zen-primary-color: var(--zen-theme-accent) !important;
                    --zen-colors-secondary: var(--zen-theme-toolbar-bg) !important;
                    --zen-colors-tertiary: var(--zen-theme-toolbar-bg-alt) !important;
                    --zen-colors-border: var(--zen-theme-accent) !important;
                    --toolbarbutton-icon-fill: var(--zen-theme-accent) !important;
                    --lwt-text-color: var(--zen-theme-text) !important;
                    --toolbar-field-background-color: var(--zen-theme-toolbar-bg) !important;
                    --toolbar-field-color: var(--zen-theme-text) !important;
                    --toolbar-field-focus-background-color: var(--zen-theme-toolbar-bg) !important;
                    --tab-selected-textcolor: var(--zen-theme-selected-tab-fg) !important;
                    --toolbar-field-focus-color: var(--zen-theme-text) !important;
                    --toolbar-color: var(--zen-theme-text) !important;
                    --newtab-text-primary-color: var(--zen-theme-text) !important;
                    --arrowpanel-color: var(--zen-theme-text) !important;
                    --arrowpanel-background: var(--zen-theme-panel-bg) !important;
                    --sidebar-text-color: var(--zen-theme-text) !important;
                    --lwt-sidebar-text-color: var(--zen-theme-text) !important;
                    --lwt-sidebar-background-color: var(--zen-theme-sidebar-bg) !important;
                    --toolbar-bgcolor: var(--zen-theme-toolbar-bg) !important;
                    --newtab-background-color: var(--zen-theme-page-bg) !important;
                    --zen-themed-toolbar-bg: var(--zen-theme-toolbar-bg-alt) !important;
                    --zen-themed-toolbar-bg-transparent: var(--zen-theme-toolbar-bg-alt) !important;
                    --zen-main-browser-background: var(--zen-theme-browser-bg) !important;
                    --toolbox-bgcolor-inactive: var(--zen-theme-toolbar-bg-alt) !important;
                    --zen-toolbar-element-bg: var(--zen-theme-toolbar-bg) !important;
                    --zen-toolbar-element-bg-hover: var(--zen-theme-hover-bg) !important;
                    --urlbarView-hover-background: var(--zen-theme-urlbar-hover-bg) !important;
                    --urlbarView-highlight-background: var(--zen-theme-urlbar-selected-bg) !important;
                }

                zen-workspace {
                  --toolbox-textcolor: var(--zen-theme-text) !important;
                }

                #historySwipeAnimationPreviousArrow,
                #historySwipeAnimationNextArrow {
                  --swipe-nav-icon-primary-color: var(--zen-theme-accent) !important;
                  --swipe-nav-icon-accent-color: var(--zen-theme-page-bg) !important;
                }

                #permissions-granted-icon {
                  color: var(--zen-theme-text) !important;
                }

                #sidebar-box,
                .sidebar-placesTree,
                #zen-workspaces-button {
                  background-color: var(--zen-theme-sidebar-bg) !important;
                }

                .urlbar-background {
                  background-color: var(--zen-theme-toolbar-bg) !important;
                }

                .content-shortcuts {
                  background-color: var(--zen-theme-page-bg) !important;
                  border-color: var(--zen-theme-accent) !important;
                }

                .urlbarView-title {
                  color: var(--zen-theme-text) !important;
                }

                .urlbarView-url {
                  color: var(--zen-theme-accent) !important;
                }

                #urlbar-input::selection {
                  background-color: var(--zen-theme-accent) !important;
                  color: var(--zen-theme-page-bg) !important;
                }

                #zenEditBookmarkPanelFaviconContainer {
                  background: var(--zen-theme-page-bg) !important;
                }

                #zen-media-controls-toolbar {
                  & #zen-media-progress-bar {
                    &::-moz-range-track {
                      background: var(--zen-theme-toolbar-bg) !important;
                    }
                  }
                }

                toolbar .toolbarbutton-1 {
                  &:not([disabled]) {
                    &:is([open], [checked])
                      > :is(
                        .toolbarbutton-icon,
                        .toolbarbutton-text,
                        .toolbarbutton-badge-stack
                      ) {
                      fill: var(--ctp-crust);
                    }
                  }
                }

                ${identityColorCss}

                #zen-toolbar-background {
                  --zen-main-browser-background-toolbar: var(--zen-theme-page-bg) !important;
                }

                #commonDialog {
                  background-color: var(--zen-theme-page-bg) !important;
                }

                #zen-browser-background {
                  --zen-main-browser-background: var(--zen-theme-page-bg) !important;
                }

                #TabsToolbar,
                hbox#titlebar,
                #zen-appcontent-navbar-container {
                  background-color: var(--zen-theme-toolbar-bg-alt) !important;
                }

                #zen-tabbox-wrapper,
                #navigator-toolbox,
                #zen-sidebar-top-buttons {
                  background-color: var(--zen-theme-sidebar-bg) !important;
                }

                #tabbrowser-tabs[orient="vertical"] .tabbrowser-tab > .tab-stack > .tab-content {
                  color: var(--zen-theme-text) !important;
                }

                #tabbrowser-tabs[orient="vertical"] .tabbrowser-tab > .tab-stack > .tab-content :is(
        ${tabForegroundSelectors}
                ) {
                  color: var(--zen-theme-text) !important;
                  fill: currentColor !important;
                  stroke: currentColor !important;
                }

                #tabbrowser-tabs .tabbrowser-tab > .tab-stack > .tab-background {
                  border-radius: var(--toolbarbutton-border-radius) !important;
                }

                #tabbrowser-tabs .tabbrowser-tab:not([selected], [multiselected]):hover > .tab-stack > .tab-background {
                  background-color: var(--zen-theme-hover-bg) !important;
                }

                ${newTabButtonSelector} {
                  background-color: transparent !important;
                  border-radius: var(--toolbarbutton-border-radius) !important;
                  color: var(--zen-theme-text) !important;
                }

                ${newTabButtonSelector}:hover {
                  background-color: var(--zen-theme-hover-bg) !important;
                }

                ${newTabButtonSelector} .toolbarbutton-icon,
                ${newTabButtonSelector} .toolbarbutton-text {
                  color: inherit !important;
                  fill: currentColor !important;
                }

                /* Local fix: upstream shadow reads like broken gray border around sidebar. */
                #zen-tabbox-wrapper #sidebar-box {
                  box-shadow: 0 0 0 1px color-mix(in srgb, var(--zen-theme-accent) 18%, transparent) !important;
                }

                /* Local fix: keep vertical selected tab contrast calm instead of bright-on-bright. */
                #tabbrowser-tabs[orient="vertical"] .tabbrowser-tab:is([selected], [multiselected]) > .tab-stack > .tab-background {
                  background-color: var(--zen-theme-selected-tab-bg) !important;
                }

                #tabbrowser-tabs[orient="vertical"] .tabbrowser-tab:is([selected], [multiselected]) > .tab-stack > .tab-content {
                  color: var(--zen-theme-selected-tab-fg) !important;
                }

                #tabbrowser-tabs[orient="vertical"] .tabbrowser-tab:is([selected], [multiselected]) > .tab-stack > .tab-content :is(
        ${tabForegroundSelectors}
                ) {
                  color: var(--zen-theme-selected-tab-fg) !important;
                  fill: currentColor !important;
                  stroke: currentColor !important;
                }

                /* Local fix: selected urlbar rows keep readable text on tinted background. */
                .urlbarView-row[selected] {
                  --zen-selected-bg: var(--zen-theme-urlbar-selected-bg) !important;
                  --zen-selected-color: var(--zen-theme-urlbar-selected-fg) !important;
                  background-color: var(--zen-theme-urlbar-selected-bg) !important;
                }

                .urlbarView-row[selected] *,
                .urlbarView-row[selected] .urlbarView-title-separator::before {
                  color: var(--zen-theme-urlbar-selected-fg) !important;
                }

                .urlbarView-row[selected] .urlbarView-url,
                .urlbarView-row[selected] .urlbarView-title-separator::before {
                  color: var(--zen-theme-urlbar-selected-muted) !important;
                }

                .urlbarView-row[selected] .urlbarView-shortcutContent,
                .urlbarView-row[selected] .urlbarView-prettyName {
                  background-color: var(--zen-theme-urlbar-chip-bg) !important;
                  color: var(--zen-theme-urlbar-selected-fg) !important;
                  fill: currentColor !important;
                  stroke: currentColor !important;
                }

                .urlbarView-row,
                .urlbarView-row-inner,
                .urlbarView-no-wrap {
                  border-radius: var(--toolbarbutton-border-radius) !important;
                }

                :is(
                  .tab-icon-image,
                  .tab-icon-stack,
                  .urlbarView-favicon,
                  .urlbarView-type-icon
                ) {
                  background-color: transparent !important;
                  box-shadow: none !important;
                }

                .urlbarView-row:not([selected]):hover,
                .urlbarView-row:not([selected]):hover .urlbarView-row-inner,
                .urlbarView-row:not([selected]):hover .urlbarView-no-wrap {
                  background-color: var(--zen-theme-urlbar-hover-bg) !important;
                }

                .urlbarView-row:is(:hover, [selected]) :is(.urlbarView-favicon, .urlbarView-type-icon),
                #tabbrowser-tabs .tabbrowser-tab:is(:hover, [selected], [multiselected]) :is(.tab-icon-image, .tab-icon-stack) {
                  background-color: transparent !important;
                  box-shadow: none !important;
                }

                menu,
                menuitem,
                menupopup {
                  color: var(--zen-theme-text) !important;
                }
      '';

      userContent = ''
        /* Generated from config.stylix.fullPalette. */
        /* Layout follows official catppuccin/zen-browser theme with repo-local fixes. */

        @-moz-document url-prefix("about:") {
          :root {
            --in-content-page-color: ${c.text} !important;
            --in-content-text-color: ${c.text} !important;
            --color-accent-primary: ${accentColor} !important;
            --color-accent-primary-hover: color-mix(in srgb, ${accentColor} 90%, white 10%) !important;
            --color-accent-primary-active: color-mix(in srgb, ${accentColor} 85%, ${c.mauve} 15%) !important;
            --link-color: ${accentColor} !important;
            --link-color-hover: color-mix(in srgb, ${accentColor} 90%, white 10%) !important;
            --link-color-active: color-mix(in srgb, ${accentColor} 85%, ${c.mauve} 15%) !important;
            --link-color-visited: ${c.mauve} !important;
            background-color: ${c.base} !important;
            --background-color-canvas: ${c.base} !important;
            --background-color-box: ${c.surface0} !important;
            --in-content-page-background: ${c.base} !important;
            --in-content-box-background: ${c.surface0} !important;
            --in-content-box-border-color: color-mix(in srgb, ${c.overlay1} 60%, transparent) !important;
            --in-content-box-info-background: color-mix(in srgb, ${c.surface0} 78%, ${c.mantle} 22%) !important;
            --in-content-border-color: color-mix(in srgb, ${c.overlay1} 60%, transparent) !important;
            --in-content-item-hover: ${c.surface1} !important;
            --in-content-item-hover-text: ${c.text} !important;
            --in-content-item-selected: color-mix(in srgb, ${accentColor} 18%, ${c.surface1} 82%) !important;
            --in-content-item-selected-text: ${c.text} !important;
            --in-content-button-text-color: ${c.text} !important;
            --in-content-button-text-color-hover: ${c.text} !important;
            --in-content-button-text-color-active: ${c.text} !important;
            --in-content-button-background: color-mix(in srgb, ${c.surface1} 55%, transparent) !important;
            --in-content-button-background-hover: ${c.surface1} !important;
            --in-content-button-background-active: ${c.surface2} !important;
            --in-content-button-border-color: transparent !important;
            --in-content-button-border-color-hover: transparent !important;
            --in-content-button-border-color-active: transparent !important;
            --in-content-primary-button-text-color: ${c.base} !important;
            --in-content-primary-button-text-color-hover: ${c.base} !important;
            --in-content-primary-button-text-color-active: ${c.base} !important;
            --in-content-primary-button-background: ${accentColor} !important;
            --in-content-primary-button-background-hover: color-mix(in srgb, ${accentColor} 90%, white 10%) !important;
            --in-content-primary-button-background-active: color-mix(in srgb, ${accentColor} 85%, ${c.mauve} 15%) !important;
            --in-content-focus-outline-color: ${accentColor} !important;
            --in-content-table-background: ${c.surface0} !important;
            --in-content-table-border-color: color-mix(in srgb, ${c.overlay1} 60%, transparent) !important;
            --in-content-table-header-background: ${accentColor} !important;
            --in-content-table-header-color: ${c.base} !important;
            --table-row-background-color: ${c.surface0} !important;
            --table-row-background-color-alternate: ${c.mantle} !important;
            --text-color-deemphasized: ${c.subtext0} !important;
            --dialog-warning-text-color: ${c.red} !important;
          }

          :root,
          body,
          .container {
            background-color: ${c.base} !important;
            color: ${c.text} !important;
          }

          .description-deemphasized,
          .text-color-deemphasized,
          .text-deemphasized,
          .description {
            color: ${c.subtext0} !important;
          }

          button,
          .button,
          .ghost-button,
          input[type="text"],
          input[type="search"],
          input[type="number"],
          input[type="email"],
          input[type="tel"],
          input[type="url"],
          input[type="password"],
          textarea,
          select {
            background-color: ${c.surface0} !important;
            color: ${c.text} !important;
            border-color: color-mix(in srgb, ${c.overlay1} 60%, transparent) !important;
          }

          .card,
          .message-bar,
          groupbox,
          moz-card,
          table,
          xul|tree,
          xul|richlistbox {
            background-color: ${c.surface0} !important;
            color: ${c.text} !important;
            border-color: color-mix(in srgb, ${c.overlay1} 60%, transparent) !important;
          }
        }

        @-moz-document url-prefix("about:config") {
          body,
          .container,
          #toolbar {
            color: ${c.text} !important;
          }

          .description,
          .config-help-text,
          .checkbox-container,
          .checkbox-container > span,
          .toggle-container-with-text,
          .toggle-container-with-text > label {
            color: ${c.subtext0} !important;
          }

          #about-config-search,
          td.cell-value > form > input[type="text"],
          td.cell-value > form > input[type="number"] {
            background-color: ${c.surface0} !important;
            color: ${c.text} !important;
          }

          #prefs {
            background-color: ${c.surface0} !important;
            color: ${c.text} !important;
            border-color: color-mix(in srgb, ${c.overlay1} 60%, transparent) !important;
          }

          #prefs > tr.odd {
            background-color: ${c.mantle} !important;
          }

          #prefs > tr:hover {
            background-color: ${c.surface1} !important;
            color: ${c.text} !important;
          }
        }

        @-moz-document url("about:newtab"), url("about:home") {
          :root {
            --newtab-background-color: ${c.base} !important;
            --newtab-background-color-secondary: ${c.surface0} !important;
            --newtab-element-hover-color: ${c.surface0} !important;
            --newtab-text-primary-color: ${c.text} !important;
            --newtab-wordmark-color: ${c.text} !important;
            --newtab-primary-action-background: ${accentColor} !important;
          }

          .icon {
            color: ${accentColor} !important;
          }

          .search-wrapper .logo-and-wordmark .logo {
            background: url("${logoUrl}") no-repeat center !important;
            display: inline-block !important;
            height: 82px !important;
            width: 82px !important;
            background-size: 82px !important;
          }

          @media (max-width: 609px) {
            .search-wrapper .logo-and-wordmark .logo {
              background-size: 64px !important;
              height: 64px !important;
              width: 64px !important;
            }
          }

          .card-outer:is(:hover, :focus, .active):not(.placeholder) .card-title {
            color: ${accentColor} !important;
          }

          .top-site-outer .search-topsite {
            background-color: ${accentColor} !important;
          }

          .compact-cards .card-outer .card-context .card-context-icon.icon-download {
            fill: ${c.green} !important;
          }
        }

        @-moz-document url-prefix("about:preferences") {
          :root {
            --zen-colors-tertiary: ${c.mantle} !important;
            --in-content-text-color: ${c.text} !important;
            --link-color: ${accentColor} !important;
            --link-color-hover: color-mix(in srgb, ${accentColor} 90%, white 10%) !important;
            --zen-colors-primary: ${c.surface0} !important;
            --in-content-box-background: ${c.surface0} !important;
            --zen-primary-color: ${accentColor} !important;
          }

          groupbox,
          moz-card {
            background: ${c.base} !important;
          }

          button,
          groupbox menulist {
            background: ${c.surface0} !important;
            color: ${c.text} !important;
          }

          .main-content {
            background-color: ${c.crust} !important;
          }

          ${identityColorCss}
        }

        @-moz-document url-prefix("about:addons") {
          :root {
            --zen-dark-color-mix-base: ${c.mantle} !important;
            --background-color-box: ${c.base} !important;
          }
        }

        @-moz-document url-prefix("about:protections") {
          :root {
            --zen-primary-color: ${c.base} !important;
            --social-color: ${c.mauve} !important;
            --coockie-color: ${c.sky} !important;
            --fingerprinter-color: ${c.yellow} !important;
            --cryptominer-color: ${c.lavender} !important;
            --tracker-color: ${c.green} !important;
            --in-content-primary-button-background-hover: color-mix(in srgb, ${c.surface1} 90%, white 10%) !important;
            --in-content-primary-button-text-color-hover: ${c.text} !important;
            --in-content-primary-button-background: ${c.surface1} !important;
            --in-content-primary-button-text-color: ${c.text} !important;
          }

          .card {
            background-color: ${c.surface0} !important;
          }
        }
      '';
    in
    {
      config = lib.mkIf (options.programs ? zen-browser && config.programs.zen-browser.enable) {
        stylix.targets.zen-browser.enableCss = false;

        programs.zen-browser.profiles = lib.genAttrs profileNames (_: {
          settings = {
            "layout.css.prefers-color-scheme.content-override" = 2;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          };
          inherit userChrome userContent;
        });
      };
    };
}
