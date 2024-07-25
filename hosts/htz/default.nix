{
  modulesPath,
  lib,
  name,
  pkgs,
  config,
  disko,
  ...
}:

{
  imports = [
    ./bootstrap.nix
    ../../common/nixos-config.nix
    ../../services/quartz-service.nix
    ../../services/stirling-pdf.nix
    ../../services/borgir.nix
  ];

  sops.secrets = {
    GITEA_PASSWORD = {
      owner = "gitea";
    };
  };

  deployment = {
    targetHost = "5.9.18.153";
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = {
      age = {
        keyFile = "/Users/szeth/.config/sops/age/keys.txt";
      };
    };
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
        allowedTCPPortRanges = [
          {
            from = 0;
            to = 65535;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 0;
            to = 65535;
          }
        ];
      };
    };
  };

  ### GITEA ###
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

  # this is not working yet
  # environment.systemPackages = with pkgs;
  #   [ (pkgs.callPackage ../../packages/quartz.nix { }) ];

  ### NTFY ###
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

  ### STIRLING-PDF ###
  services.stirling-pdf = {
    enable = true;
    directory = "/var/lib/stirling-pdf";
  };

  ### UPTIME-KUMA ###
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "0.0.0.0"; # otherwise it binds to 127.0.0.1
      PORT = "3001";
    };
  };

  ### BORG ###
  services.borgir = {
    enable = true;
    repoId = "parl5yw3";
    paths = [ "/var/lib" ];
    # maybe exclude /var/lib/private/uptime-kuma/kuma.db since it's super big for some reason
    # exclude = [
    #   "/var/lib/systemd"
    # ];
  };

  ### SYNCTHING ###
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiAddress = "0.0.0.0:8384";

    settings = {
      options = {
        # no usage reporting
        urAccepted = -1;

        globalAnnounceEnabled = false;
      };

      # ideally we don't hardcode the password here
      # gui = {
      #   user = "szeth";
      #   password = "password";
      # };

      devices = {
        mackie = {
          id = "DJQMJTH-2MVT7XX-OUIEFR3-3B56OFE-ODY5WI5-RQNHGX7-KTKQZZB-GX3ROQA";
          autoAcceptFolders = true;
        };

        bae_phone = {
          id = "FMJTP3L-S47GWT4-ET5QX2S-44H6DOE-TSFIO2M-AIOUIA4-3OYPG2R-2LZ7LA7";
          autoAcceptFolders = true;
        };
      };

      folders = {
        "~/test-sync" = {
          id = "wjruu-pwtpn";
          devices = [ "mackie" ];
          type = "sendreceive";
          label = "Test Sync";
        };

        "~/bae/dcim" = {
          id = "yzu5h-7arf3";
          devices = [ "bae_phone" ];
          type = "receiveencrypted";
          label = "DCIM";
        };

        "~/bae/Opera" = {
          id = "jhqbs-uuk52";
          devices = [ "bae_phone" ];
          type = "receiveencrypted";
          label = "Opera";
        };
      };
    };
  };

  ### FRESHRSS ###
  # TODO: set this up
  # services.freshrss = {
  #   enable = true;
  #   port = 8036;
  # };
}
