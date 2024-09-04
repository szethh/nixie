{ pkgs, ... }:
{
  # "spoti.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://kite:8338
  # '';

  # "yt.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://kite:8003
  # '';

  "sabnzbd.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:6755
  '';

  # "bookdl.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://kite:8033
  # '';

  "pic.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:2283
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

  # "change.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://kite:5003
  # '';

  "adh.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:3765
  '';

  "pdf.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:8080
  '';

  "bazarr.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:6767
  '';

  "prowlarr.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:9696
  '';

  "radarr.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:7878
  '';

  "jelly.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8096
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
    reverse_proxy http://nixvm:8988
  '';

  "readarr.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8787
  '';

  "lidarr.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8686
  '';

  "calibre.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8083
  '';

  # "translate.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://kite:5050
  # '';

  "home.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://homeassistant:8123
  '';

  "qbit.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8090
  '';

  "uptime.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:3001
  '';

  "sonarr.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:8989
  '';

  # "docs.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://kite:8000
  # '';

  # "plex.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://pve:32400
  # '';

  # "pihole.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://pve:8020
  # '';

  "ab.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:13378
  '';

  "rss.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:80
  '';

  "file.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://pve:8560
  '';

  # "sync-pve.int.bnuuy.net".extraConfig = ''
  #   reverse_proxy http://pve:8384
  # '';

  "sync-htz.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:8384
  '';

  "git.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:3005
  '';

  "gpt.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://nixvm:11111
  '';

  "jupyter.int.bnuuy.net".extraConfig = ''
    reverse_proxy http://htz:8888
  '';
}
