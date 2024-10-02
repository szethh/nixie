{ pkgs, ... }:
{
  "bnuuy.net".extraConfig = ''
    respond "jijiji"
  '';

  "ntfy.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:8044
  '';

  # this is the internal domain instead
  # "git.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://htz:3000
  # '';

  "hci.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8020
  '';

  "house.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8333
  '';

  "home.bnuuy.net".extraConfig = ''
    reverse_proxy http://hass:8123
  '';

  "social.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:8056
  '';

  "analytics.bnuuy.net".extraConfig = ''
    rewrite /js/index.js /js/plausible.js

    reverse_proxy http://htz:8005
  '';

  "*.bnuuy.net".extraConfig = ''
    # Check if the subdomain doesn't match int.bnuuy.net
    @notIntSubdomain {
        not path_regexp ^/.*int\.bnuuy\.net/.*
    }

    # Redirect only if it's not int.*
    redir @notIntSubdomain https://{labels.2}.int.{labels.1}.{labels.0}{uri}
  '';
}
