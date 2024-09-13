{ lib, config, ... }:

let
  cfg = config.services.mastodon;
  # since we have multiple sockets, we need to concat them
  sockets = lib.concatStringsSep " " (
    map (i: "unix//run/mastodon-streaming/streaming-${toString i}.socket") (
      lib.range 1 cfg.streamingProcesses
    )
  );
in
{
  services.caddy = {
    enable = true;
    enableReload = false;

    globalConfig = ''
      auto_https off
    '';

    # see https://nixos.wiki/wiki/Mastodon#Using_Caddy_as_a_server
    virtualHosts.":8056".extraConfig = ''
      handle_path /system/* {
        file_server * {
          root /var/lib/mastodon/public-system
        }
      }

      handle /api/v1/streaming/* {
        # the default from the wiki assumes 1 socket
        #reverse_proxy  unix//run/mastodon-streaming/streaming.socket
        # however we have multiple sockets
        reverse_proxy ${sockets}
      }

      route * {
        file_server * {
          root ${cfg.package}/public
          pass_thru
        }
        reverse_proxy * unix//run/mastodon-web/web.socket {
          # this is needed! otherwise it will go into a redirect loop
          # https://github.com/mastodon/mastodon/discussions/19544#discussioncomment-4613320
          header_up X-Forwarded-Proto https
          # header_up X-Forwarded-Host {host}
        }
      }

      handle_errors {
        root * ${cfg.package}/public
        rewrite 500.html
        file_server
      }

      encode gzip

      header /* {
        Strict-Transport-Security "max-age=31536000;"
      }
      header /emoji/* Cache-Control "public, max-age=31536000, immutable"
      header /packs/* Cache-Control "public, max-age=31536000, immutable"
      header /system/accounts/avatars/* Cache-Control "public, max-age=31536000, immutable"
      header /system/media_attachments/files/* Cache-Control "public, max-age=31536000, immutable"
    '';
  };

  users.users.caddy.extraGroups = [ "mastodon" ];
  systemd.services.caddy.serviceConfig.ReadWriteDirectories = lib.mkForce [
    "/var/lib/caddy"
    "/run/mastodon-web"
  ];
}
