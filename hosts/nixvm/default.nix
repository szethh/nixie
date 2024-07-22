{ config, pkgs, disko, ... }:

{
  imports = [ ./proxmox.nix ];

  sops.secrets = { PAPERLESS_ADMIN_PASSWORD = { owner = "paperless"; }; };

  ### DEPLOYMENT ###
  deployment = {
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = { age = { keyFile = "/Users/szeth/.config/sops/age/keys.txt"; }; };
  };

  ### AUDIOBOOKSHELF ###
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    # relative to /var/lib
    dataDir = "audiobookshelf";
  };

  ### SHIORI ###
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

  ### PAPERLESS-NGX ###
  services.paperless = {
    enable = true;
    # default, but to be explicit
    package = pkgs.paperless-ngx;
    user = "paperless";
    dataDir = "/var/lib/paperless-ngx";
    port = 28981; # default
    address = "0.0.0.0";
    passwordFile = config.sops.secrets.PAPERLESS_ADMIN_PASSWORD.path;

    settings = {
      PAPERLESS_URL = "https://paper.int.bnuuy.net";
      PAPERLESS_ALLOWED_HOSTS = "paper.int.bnuuy.net,nixvm";
      #PAPERLESS_CSRF_TRUSTED_ORIGINS=https://*.{{ vault.base_url }};
      PAPERLESS_OCR_LANGUAGES = [ "eng" "nld" "spa" ];
      PAPERLESS_OCR_LANGUAGE = "eng+nld+spa";
      PAPERLESS_FILENAME_FORMAT = "{title}";
      # on the first run, this will create the admin user
      # it's better to not set this, the default is "admin"
      # then use the document importer to import our actual user (alongside documents etc)
      # then we can just delete the admin user
      # PAPERLESS_ADMIN_USER = "szeth";
    };

  };
}
