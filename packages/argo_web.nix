{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.argoWeb;
in
{
  options.services.argoWeb = {
    enable = mkEnableOption "Cloudflare Argo Tunnel";

    tokenPath = mkOption {
      type = types.path;
      description = "Cloudflare Argo Tunnel token";
    };

    dataDir = mkOption {
      default = "/var/lib/argoWeb";
      type = types.path;
      description = ''
        The data directory, for storing credentials.
      '';
    };

    package = mkOption {
      default = pkgs.cloudflared;
      defaultText = "pkgs.cloudflared";
      type = types.package;
      description = "cloudflared package to use.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.argoWeb = {
      description = "Cloudflare Argo Tunnel";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ]; # systemd-networkd-wait-online.service
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.runtimeShell} -c '${cfg.package}/bin/cloudflared tunnel --no-autoupdate run --token $(cat ${cfg.tokenPath})'";
        Type = "simple";
        User = "argoWeb";
        Group = "argoWeb";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        LimitNPROC = 512;
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "full";
        ReadWriteDirectories = cfg.dataDir;
      };
    };
  };
}
