{
  modulesPath,
  lib,
  name,
  pkgs,
  config,
  ...
}:

{
  imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
    ../../common/nixos-config.nix
    ../../services/borgir.nix
  ];

  sops.secrets = {
    CLOUDFLARED_TOKEN = {
      owner = "argoWeb";
    };
    CF_DNS_TOKEN = {
      owner = "argoWeb";
    };
  };

  sops.templates.CF_DNS_TOKEN.content = ''
    CF_DNS_TOKEN="${config.sops.placeholder.CF_DNS_TOKEN}"
  '';

  # since we are binding caddy to 127.0.0.1 we don't need to open ports :)
  networking.firewall = {
    enable = true;
  };

  #### SYSTEM ####
  boot.isContainer = false;

  swapDevices = [
    {
      device = "/swapfile"; # Location of the swap file
      size = 1024; # Size of swap in MB (1GB in this case)
    }
  ];

  # we may have low space but we have even less ram
  boot.tmp.useTmpfs = lib.mkForce false;

  users = {
    users = {
      argoWeb = {
        home = "/var/lib/argoWeb";
        createHome = true;
        isSystemUser = true;
        group = "argoWeb";
      };
    };

    groups = {
      argoWeb.members = [ "argoWeb" ];
    };
  };

  # packages
  environment.systemPackages = with pkgs; [ caddy ];

  #### CLOUDFLARED ARGO TUNNEL ####
  require = [ ../../packages/argo_web.nix ];

  services.argoWeb = {
    enable = true;
    tokenPath = config.sops.secrets.CLOUDFLARED_TOKEN.path;
  };

  # allow caddy to bind to ports < 1024
  systemd.services.caddy.serviceConfig = {
    AmbientCapabilities = "cap_net_bind_service";
    CapabilityBoundingSet = "cap_net_bind_service";
    EnvironmentFile = "${config.sops.templates.CF_DNS_TOKEN.path}";
  };
  # let caddyWithPlugins = with pkgs; stdenv.mkDerivation { pkgs.callPackage ./packages/caddy_plugins.nix { }; }
  # in {
  services.caddy = {
    enable = true;
    enableReload = false;

    # servers.production.services.http.port = 443;

    # ideally we could use this, so we could customize the plugins
    # but i can't get it to work. so we hardcode the plugins and their hash in caddy_plugins.nix
    # package = pkgs.callPackage ../../packages/caddy_plugins.nix { plugins = [
    #     "github.com/caddy-dns/acmedns@18621dd3e69e048eae80c4171ef56cb576dce2f4"
    #     # "github.com/caddy-dns/cloudflare"
    #   ];
    # };
    package = pkgs.caddy-cloudflare;
    logDir = "/var/log/caddy";
    logFormat = ''
      level DEBUG
      format json
      output file ${config.services.caddy.logDir}/access.log
    '';
    user = "argoWeb";
    group = "argoWeb";

    # the acme_dns line needs the cloudflare module. for this we use xcaddy
    # the env variable is set above, in systemd.services.caddy.serviceConfig.ExecStartPre
    globalConfig = ''
      debug

      acme_dns cloudflare {env.CF_DNS_TOKEN}

      default_bind 127.0.0.1
    '';

    virtualHosts = import ../../apps/proxy/public.nix { inherit pkgs; };
  };
  # }

  services.borgir = {
    enable = true;
    repoId = "ddwq6062";
    paths = [ "/var/lib" ];
  };
}
