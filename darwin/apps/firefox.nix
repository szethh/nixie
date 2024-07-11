{ pkgs, inputs, ... }:
{
  enable = true;
  package = null;

  profiles.szeth = {
    isDefault = true;

    extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
      bitwarden
      consent-o-matic
      floccus
      multi-account-containers
      sponsorblock
      translate-web-pages
      ublock-origin
    ];

    settings = {
      # auto enable extensions
      extensions.autoDisableScopes = 0;

      # home page
      browser.newtabpage.activity-stream.showSearch = false;
      browser.newtabpage.activity-stream.showSponsoredTopSites = false;
      
      # search
      browser.search.suggest.enabled = false;
      browser.search.separatePrivateDefault.ui.enabled = true;

      browser.contentblocking.category = "standard";
      datareporting.healthreport.uploadEnabled = false;
    };

    search = {
      default = "Google";
      privateDefault = "DuckDuckGo";
      # force apply these settings, otherwise firefox overrides them on launch
      force = true;
    };

    search.engines = {
      "Bing".metaData.hidden = true;
      "Google".metaData.alias = "!g"; # builtin engines only support specifying one additional alias
      "DuckDuckGo".metaData.alias = "!d";

      "Nix Packages" = {
        urls = [{
          template = "https://search.nixos.org/packages";
          params = [
            { name = "type"; value = "packages"; }
            { name = "query"; value = "{searchTerms}"; }
          ];
        }];

        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "!np" ];
      };
    };
  };
}
