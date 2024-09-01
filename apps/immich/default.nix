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

  users.users.immich = {
    isNormalUser = true;
    description = "Immich stack user";
    # grr we have to manually set the uid
    # so that sops can write the .env file
    # otherwise it gets read as null...
    uid = 1002;
    home = "/var/lib/immich";
    createHome = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "docker" ];
  };

  deployment.keys.immich-compose = {
    name = "docker-compose.yml";
    destDir = "/var/lib/immich";
    keyFile = ./docker-compose.yml;
    user = config.users.users.immich.name;
    group = "docker";
    permissions = "0644";
  };

  # Copy the .env file to the user's home directory
  system.activationScripts.copyImmichEnvFile = {
    text = ''
      cp ${config.sops.templates.IMMICH_ENV.path} ${config.users.users.immich.home}/.env
      chown ${config.users.users.immich.name}:${config.users.users.immich.group} ${config.users.users.immich.home}/.env
      chmod 400 ${config.users.users.immich.home}/.env
    '';
  };
}
