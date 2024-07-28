{
  pkgs,
  lib,
  config,
  ...
}:

let
  src = pkgs.fetchFromGitHub {
    owner = "szethh";
    repo = "hci-website";
    rev = "main";
    sha256 = "sha256-/rjH1w4LdFnC0SwhJM2lDAe3nZR7czdpk3KQeVOx8Lc=";
  };
in
{
  services.caddy.virtualHosts.":8020" = {
    # hostName = "hci.bnuuy.net";
    extraConfig = ''
      root * ${src}/web
      file_server
    '';
    # this is the default, but since we are binding to a port instead of a domain, we need to set it
    # otherwise the logfile will be called 8020.log which is weird
    logFormat = "output file ${config.services.caddy.logDir}/access-hci.bnuuy.net.log";
  };
}
