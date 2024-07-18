{ modulesPath, lib, name, pkgs, config, disko, ... }:

{
  imports = [
    # not sure what this does
    ./bootstrap.nix
    ../../common/szeth.nix
    ../../services/quartz-service.nix
  ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "${config.deployment.keys.age.destDir}/age";
  sops.secrets = { GITEA_PASSWORD = { owner = "gitea"; }; };

  deployment = {
    targetHost = "5.9.18.153";
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = { age = { keyFile = "/Users/szeth/.config/sops/age/keys.txt"; }; };
  };

  programs.zsh.enable = true;

  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];

    interfaces = {
      eth0 = {
        allowedTCPPorts = [ ]; # No open TCP ports
        allowedUDPPorts = [ ]; # No open UDP ports
      };

      tailscale0 = {
        allowedTCPPortRanges = [{
          from = 0;
          to = 65535;
        }];
        allowedUDPPortRanges = [{
          from = 0;
          to = 65535;
        }];
      };
    };
  };

  services.gitea = {
    enable = true;
    settings = {
      # turn on only after setting up the admin account
      service.DISABLE_REGISTRATION = true;
      server = {
        HTTP_PORT = 3005;
        PROTOCOL = "http";
        DOMAIN = "git.int.bnuuy.net";
        SSH_DOMAIN = "git.int.bnuuy.net";
        ROOT_URL = "https://git.int.bnuuy.net";
      };
      database = {
        name = "gitea";
        type = "sqlite3";
        user = "gitea";
        passwordFile = config.sops.secrets.GITEA_PASSWORD.path;
        # this is the default, just to be explicit
        path = "${config.services.gitea.stateDir}/data/gitea.db";
        createDatabase = true;
      };
    };
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      # this is the default, just to be explicit
      base-url = "https://ntfy.bnuuy.net";
      listen-http = ":8044";
      behind-proxy = true;
      upstream-base-url = "https://ntfy.sh";
    };
  };

  # this is not working yet
  # services.quartz = {
  #   enable = true;
  #   directory = "/home/szeth/quartz/content";
  #   output = "/home/szeth/quartz/public";
  # };

  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "0.0.0.0"; # otherwise it binds to 127.0.0.1
      PORT = "3001";
    };
  };

}
