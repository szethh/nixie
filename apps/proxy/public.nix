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
    reverse_proxy http://homeassistant:8123
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
