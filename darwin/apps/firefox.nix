{ pkgs, inputs, ... }:
{
  enable = true;
  package = null;

  profiles.szeth = {
      isDefault = true;

      extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
          ublock-origin
          bitwarden
        #   # multi-account-containers
        #   consent-o-matic
        #   sponsorblock
        #   translate-web-pages
      ];
  };
}
