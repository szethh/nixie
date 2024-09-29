{ pkgs, config, ... }:
{
  sops.secrets = {
    IMMICH_DB_PASSWORD = {
      owner = "immich";
    };
  };

  sops.templates.IMMICH_ENV.content = ''
    # You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

    # The location where your uploaded files are stored
    UPLOAD_LOCATION=./library

    # The Immich version to use. You can pin this to a specific version like "v1.71.0"
    IMMICH_VERSION=release

    # Connection secret for postgres. You should change it to a random password
    DB_PASSWORD=${config.sops.placeholder.IMMICH_DB_PASSWORD}

    # The values below this line do not need to be changed
    ###################################################################################
    DB_HOSTNAME=immich_postgres
    DB_USERNAME=postgres
    DB_DATABASE_NAME=immich
    DB_DATA_LOCATION=./postgres

    REDIS_HOSTNAME=immich_redis
  '';

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    # openFirewall = true;
    mediaLocation = "/var/lib/immich";
    secretsFile = config.sops.templates.IMMICH_ENV.path;
    database.createDB = true;
  };
}
