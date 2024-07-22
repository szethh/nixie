{ pkgs, disko, ... }:

{
  imports = [ ./proxmox.nix ];

  deployment = {
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = { age = { keyFile = "/Users/szeth/.config/sops/age/keys.txt"; }; };
  };

  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    # relative to /var/lib
    dataDir = "audiobookshelf";
  };

  services.shiori = {
    enable = true;
    port = 8070;
  };

  # for some reason the shiori service doesn't create the user
  users.users.shiori = {
    isSystemUser = true;
    group = "shiori";
    home = "/var/lib/shiori";
  };

  users.groups.shiori = { };

}
