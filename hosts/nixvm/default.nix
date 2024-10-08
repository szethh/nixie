{
  config,
  pkgs,
  pkgsStable,
  pkgsUnstable,
  lib,
  ...
}:

{
  imports = [
    ./proxmox.nix
    ./containers
    ../../services/mega-sync.nix
    ../../services/borgir.nix
    ../../apps/home-tools/service.nix
    ../../apps/hci-website.nix
    ../../apps/immich
  ];

  sops.secrets = {
    PAPERLESS_ADMIN_PASSWORD = {
      owner = "paperless";
    };
    MEGA_USERNAME = {
      owner = "mega";
    };
    MEGA_PASSWORD = {
      owner = "mega";
    };
    MEGA_TOTP_SECRET = {
      owner = "mega";
    };
    BORG_PASSPHRASE = {
      owner = "root";
    };
    CF_DNS_TOKEN = {
      owner = "caddy";
    };
  };

  # format secret as env file
  sops.templates.CF_DNS_TOKEN.content = ''
    CF_DNS_TOKEN="${config.sops.placeholder.CF_DNS_TOKEN}"
  '';

  ### MOUNT STORAGE ###
  fileSystems."/mnt/storage" = {
    # mount storage from pve
    device = "100.78.187.125:/mnt/storage";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
    fsType = "nfs";
  };

  # special group for nfs
  # FIXME: THIS DOES NOT WORK YET
  users.groups.storage.gid = 555;
  users.users.root.extraGroups = [ "storage" ];

  ### MAP NFS USERS ###
  # THIS DOES NOT WORK YET
  # we have to use mkForce since fileSystems already sets this
  # services.nfs.idmapd.settings = lib.mkForce {
  #   # this seems sketchy, i'm allowing everyone to access the nfs share
  #   General = {
  #     Domain = "bnuuy";
  #   };
  #   Mapping = {
  #     "Nobody-User" = "szeth";
  #     "Nobody-Group" = "szeth";
  #   };
  # };

  ### AUDIOBOOKSHELF ###
  users.users.audiobookshelf.extraGroups = [ "storage" ];
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    # relative to /var/lib
    dataDir = "audiobookshelf";
    package = pkgsUnstable.audiobookshelf;
  };

  ### SHIORI ###
  services.shiori = {
    enable = true;
    package = pkgsUnstable.shiori;
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
    package = pkgsUnstable.paperless-ngx;
    user = "paperless";
    dataDir = "/var/lib/paperless-ngx";
    port = 28981; # default
    address = "0.0.0.0";
    passwordFile = config.sops.secrets.PAPERLESS_ADMIN_PASSWORD.path;

    settings = {
      PAPERLESS_URL = "https://paper.int.bnuuy.net";
      PAPERLESS_ALLOWED_HOSTS = "paper.int.bnuuy.net,nixvm";
      #PAPERLESS_CSRF_TRUSTED_ORIGINS=https://*.{{ vault.base_url }};
      PAPERLESS_OCR_LANGUAGES = [
        "eng"
        "nld"
        "spa"
      ];
      PAPERLESS_OCR_LANGUAGE = "eng+nld+spa";
      PAPERLESS_FILENAME_FORMAT = "{title}";
      # on the first run, this will create the admin user
      # it's better to not set this, the default is "admin"
      # then use the document importer to import our actual user (alongside documents etc)
      # then we can just delete the admin user
      # PAPERLESS_ADMIN_USER = "szeth";
    };
  };

  # TODO: megasync
  services.megacmd = {
    enable = true;
    dataDir = "/var/lib/megacmd";
    package = pkgsUnstable.megacmd;

    usernameFile = config.sops.secrets.MEGA_USERNAME.path;
    passwordFile = config.sops.secrets.MEGA_PASSWORD.path;
    totpSecretFile = config.sops.secrets.MEGA_TOTP_SECRET.path;

    syncPaths = [
      {
        enable = true;
        localPath = "/var/lib/paperless-ngx/media/documents/originals";
        remotePath = "/Documents/papers";
      }
    ];
  };

  # Set ACLs for the mega user to access the paperless documents directory
  environment.systemPackages = with pkgs; [ acl ];
  system.activationScripts.setACLs = {
    text = ''
      ${pkgs.acl}/bin/setfacl -R -m u:mega:rwx /var/lib/paperless-ngx/media/documents/originals
      # set the default ACL to the folder
      ${pkgs.acl}/bin/setfacl -dR -m u:mega:rwx /var/lib/paperless-ngx/media/documents/originals
    '';
  };

  ### DNSMASQ ###
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      port = 54;
      server = [ "1.1.1.1" ];
      address = [
        "/int.bnuuy.net/192.168.50.44"
        "/int.bnuuy.net/100.68.170.95"
      ];
      log-queries = true;
      log-facility = "/tmp/ad-block.log";
    };
  };

  ### ADGUARDHOME ###
  # double check that this gets added to /etc/resolv.conf
  # otherwise the proxy doesn't work
  networking.nameservers = [ "100.100.100.100" ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  services.adguardhome = {
    enable = true;
    port = 3765;
    package = pkgsUnstable.adguardhome;
    openFirewall = true;
    # don't squash settings set in the ui
    mutableSettings = true;
    # gotta have this defined for the config to be generated
    settings = {
      dns = {
        private_networks = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.50.0/16"
          # Tailscale
          "100.64.0.0/10"
        ];
      };
      # this does not work like pihole/dnsmasq's dns overrides
      # only the first one is used
      # we want both, to have a fallback if you are not in lan/tailscale
      # filtering = {
      #   # redirect int.bnuuy.net to internal dns server
      #   rewrites = [
      #     {
      #       domain = "*.int.bnuuy.net";
      #       answer = "100.68.170.95";
      #     }
      #     {
      #       domain = "*.int.bnuuy.net";
      #       answer = "192.168.50.44";
      #     }
      #   ];
      # };
    };
  };

  ### CADDY ###
  # allow caddy to listen on port 443
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      443
      80
      53 # for adguardhome
    ];
  };

  systemd.services.caddy.serviceConfig = {
    AmbientCapabilities = "cap_net_bind_service";
    CapabilityBoundingSet = "cap_net_bind_service";
    EnvironmentFile = "${config.sops.templates.CF_DNS_TOKEN.path}";
  };
  services.caddy = {
    enable = true;
    enableReload = false;

    logDir = "/var/log/caddy";
    logFormat = ''
      level DEBUG
      format json
      output file ${config.services.caddy.logDir}/access.log
    '';
    user = "caddy";
    group = "caddy";
    package = pkgsStable.caddy-cloudflare;

    # the acme_dns line needs the cloudflare module. for this we use xcaddy
    # the env variable is set above, in systemd.services.caddy.serviceConfig.ExecStartPre
    globalConfig = ''
      debug

      acme_dns cloudflare {env.CF_DNS_TOKEN}
    '';

    virtualHosts = import ../../apps/proxy/internal.nix { inherit pkgs; };
  };

  ### JELLYSEERR ###
  services.jellyseerr = {
    enable = true;
    port = 5055;
    package = pkgsUnstable.jellyseerr;
    # runs on /var/lib/jellyseerr
  };

  ### JELLYFIN ###
  services.jellyfin = {
    enable = true;
    dataDir = "/var/lib/jellyfin";
  };

  ### HOME-TOOLS ###
  services.home-tools = {
    enable = true;
  };

  ### OLLAMA ###
  # we are using ollama on the windows vm instead, it has a gpu
  # services.ollama = {
  #   enable = true;
  #   loadModels = [
  #     "llama3.1:8b"
  #     "mistral:7b"
  #   ];
  # };

  services.open-webui = {
    enable = true;
    port = 11111;
    host = "0.0.0.0";
  };

  ### BORG ###
  services.borgir = {
    enable = true;
    repoId = "zwek2hvg";
    paths = [ "/var/lib" ];
    exclude = [
      # very large paths
      "/var/lib/systemd"
      "/var/lib/paperless-ngx/classification_model.pickle"
      "/var/lib/private/ollama" # don't backup ollama models
      "/var/lib/docker"

      # don't need these yet
      # "/var/lib/libvirt"
    ];
  };
}
