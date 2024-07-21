{ modulesPath, lib, name, pkgs, config, ... }:

{
  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      ../../common/szeth.nix
      ../../common/nixos-config.nix
    ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "${config.deployment.keys.age.destDir}/age";
  sops.secrets = {
    CLOUDFLARED_TOKEN = { owner = "argoWeb"; };
    CF_DNS_TOKEN = { owner = "argoWeb"; };
  };

  system.stateVersion = "24.05";

  deployment = {
    targetHost = "nixie"; # "104.248.200.219";
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = { age = { keyFile = "/Users/szeth/.config/sops/age/keys.txt"; }; };
  };

  programs.zsh.enable = true;

  networking.hostName = name;

  services.tailscale.enable = true;

  # since we are binding caddy to 127.0.0.1 we don't need to open ports :)
  networking.firewall = { enable = true; };

  #### SYSTEM ####
  boot.isContainer = false;
  time.timeZone = "Europe/Amsterdam";

  users = {
    mutableUsers = false; # Disable passwd

    users = {
      root.hashedPassword = "*";

      argoWeb = {
        home = "/var/lib/argoWeb";
        createHome = true;
        isSystemUser = true;
        group = "argoWeb";
      };
    };

    groups = { argoWeb.members = [ "argoWeb" ]; };
  };

  # packages
  environment.systemPackages = with pkgs; [ caddy ];

  #### CLOUDFLARED ARGO TUNNEL ####
  require = [ ../../packages/argo_web.nix ];

  nixpkgs.config.allowUnfree = true;
  services.argoWeb = {
    enable = true;
    tokenPath = config.sops.secrets.CLOUDFLARED_TOKEN.path;
  };

  # allow caddy to bind to ports < 1024
  systemd.services.caddy.serviceConfig = {
    AmbientCapabilities = "cap_net_bind_service";
    CapabilityBoundingSet = "cap_net_bind_service";
    # ExecStart = "${pkgs.caddy}/bin/caddy run --config /etc/caddy/Caddyfile";
    ExecStartPre =
      "${pkgs.runtimeShell} -c 'export CF_DNS_TOKEN=$(cat ${config.sops.secrets.CF_DNS_TOKEN.path})'";
  };
  # let caddyWithPlugins = with pkgs; stdenv.mkDerivation { pkgs.callPackage ./packages/caddy_plugins.nix { }; }
  # in {
  services.caddy = {
    enable = true;

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
    user = "argoWeb";
    group = "argoWeb";

    # the acme_dns line needs the cloudflare module. for this we use xcaddy
    # the env variable is set above, in systemd.services.caddy.serviceConfig.ExecStartPre
    globalConfig = ''
      debug

      acme_dns cloudflare {env.CF_DNS_TOKEN}

      default_bind 127.0.0.1
    '';

    virtualHosts = {
      "bnuuy.net".extraConfig = ''
        respond "jijiji"
      '';

      "ntfy.bnuuy.net".extraConfig = ''
        reverse_proxy http://htz:8044
      '';

      # this is the internal domain instead
      # "git.bnuuy.net".extraConfig = ''
      #   reverse_proxy http://htz:3000
      # '';

      "hci.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8020
      '';

      "house.bnuuy.net".extraConfig = ''
        reverse_proxy http://kite:8333
      '';

      "home.bnuuy.net".extraConfig = ''
        reverse_proxy http://homeassistant:8123
      '';

      "*.bnuuy.net".extraConfig = ''
        # Check if the subdomain doesn't match int.bnuuy.net
        @notIntSubdomain {
            not path_regexp ^/.*int\.bnuuy\.net/.*
        }

        # Redirect only if it's not int.*
        redir @notIntSubdomain https://{labels.2}.int.{labels.1}.{labels.0}{uri}
      '';
    };
  };
  # }
}
