{
  config,
  pkgs,
  disko,
  ...
}:

{
  imports = [
    ./proxmox.nix
    ../../services/mega-sync.nix
    ../../services/borgir.nix
    ../../apps/home-tools/service.nix
    ../../apps/hci-website.nix
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

  ### DEPLOYMENT ###
  deployment = {
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = {
      age = {
        keyFile = "/Users/szeth/.config/sops/age/keys.txt";
      };
    };
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

  ### ADGUARDHOME ###
  services.adguardhome = {
    enable = true;
    port = 3765;
    openFirewall = true;
    # don't squash settings set in the ui
    mutableSettings = true;
    # gotta have this defined for the config to be generated
    settings = {
      filtering = {
        # redirect int.bnuuy.net to internal dns server
        rewrites = [
          {
            domain = "*.int.bnuuy.net";
            answer = "100.68.170.95";
          }
          {
            domain = "*.int.bnuuy.net";
            answer = "192.168.50.44";
          }
        ];
      };
    };
  };

  ### CADDY ###
  # allow caddy to listen on port 443
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      443
      80
    ];
  };

  systemd.services.caddy.serviceConfig = {
    AmbientCapabilities = "cap_net_bind_service";
    CapabilityBoundingSet = "cap_net_bind_service";
    EnvironmentFile = "${config.sops.templates.CF_DNS_TOKEN.path}";
  };
  services.caddy = {
    enable = true;
    logDir = "/var/log/caddy";
    logFormat = ''
      level DEBUG
      format json
      output file ${config.services.caddy.logDir}/access.log
    '';
    user = "caddy";
    group = "caddy";
    package = pkgs.caddy-cloudflare;

    # the acme_dns line needs the cloudflare module. for this we use xcaddy
    # the env variable is set above, in systemd.services.caddy.serviceConfig.ExecStartPre
    globalConfig = ''
      debug

      acme_dns cloudflare {env.CF_DNS_TOKEN}
    '';

    virtualHosts = {
      "spoti.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8338
      '';

      "yt.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8003
      '';

      "sabnzbd.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:6755
      '';

      "bookdl.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8033
      '';

      "pic.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:2283
      '';

      "proxmox.int.bnuuy.net".extraConfig = ''
        reverse_proxy https://pve:8006 {
          transport http {
            tls_insecure_skip_verify
          }
        }
      '';

      "paper.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://nixvm:28981
      '';

      "change.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:5003
      '';

      "adh.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://nixvm:3765
      '';

      "pdf.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://htz:8080
      '';

      "bazarr.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:6767
      '';

      "prowlarr.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:9696
      '';

      "radarr.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:7878
      '';

      "jelly.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://pve:8096
      '';

      "request.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://nixvm:5055
      '';

      "dsm.int.bnuuy.net".extraConfig = ''
        reverse_proxy https://oreonas:5001 {
          transport http {
            tls_insecure_skip_verify
          }
        }
      '';

      "shiori.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://nixvm:8070
      '';

      "sonarrtv.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8988
      '';

      "readarr.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8787
      '';

      "lidarr.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8686
      '';

      "calibre.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8083
      '';

      "translate.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:5050
      '';

      "home.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://homeassistant:8123
      '';

      "qbit.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8090
      '';

      "uptime.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://htz:3001
      '';

      "sonarr.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8989
      '';

      "docs.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8000
      '';

      "plex.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://pve:32400
      '';

      "pihole.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://pve:8020
      '';

      "ab.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://nixvm:13378
      '';

      "rss.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://htz:8036
      '';

      "file.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://pve:8560
      '';

      "sync-pve.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://pve:8384
      '';

      "sync-htz.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://htz:8384
      '';

      "git.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://htz:3005
      '';

      "gpt.int.bnuuy.net".extraConfig = ''
        reverse_proxy http://nixvm:11111
      '';
    };
  };

  ### JELLYSEERR ###
  # not working yet
  # the proxy is funky
  # https://request.int.bnuuy.net/ returns a 502
  services.jellyseerr = {
    enable = true;
    port = 5055;
    # runs on /var/lib/jellyseerr
  };

  ### HOME-TOOLS ###
  services.home-tools = {
    enable = true;
  };

  ### OLLAMA ###
  services.ollama = {
    enable = true;
    loadModels = [
      "llama3.1:8b"
      "mistral:7b"
    ];
  };

  services.open-webui = {
    enable = true;
    port = 11111;
    host = "0.0.0.0";
  };

  ### BORG ###
  services.borgir = {
    enable = true;
    repoId = "zwek2hvg";
    paths = [
      "/var/lib"
      "/root/test"
    ];
    exclude = [
      # very large paths
      "/var/lib/systemd"
      "/var/lib/paperless-ngx/classification_model.pickle"
      "/var/lib/private/ollama" # don't backup ollama models

      # don't need these yet
      # "/var/lib/libvirt"
      # "/var/lib/docker"
    ];
  };
}
