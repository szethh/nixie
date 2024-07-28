{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  htPkg = pkgs.callPackage ./package.nix { };

  cfg = config.services.home-tools;
in
{
  options.services.home-tools = {
    enable = mkEnableOption "Home Tools Service";

    user = mkOption {
      type = types.str;
      default = "home-tools";
      description = "The user to run the service as.";
    };

    group = mkOption {
      type = types.str;
      default = "home-tools";
      description = "The group to run the service as.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/home-tools";
      description = "The data directory.";
    };

    port = mkOption {
      type = types.port;
      default = 8333;
      description = "The port to run the local preview server on.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.home-tools = {
      enable = true;
      description = "Home Tools Service";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.nodejs}/bin/node ${htPkg}/lib/node_modules/home-tools/build/index.js";
        WorkingDirectory = cfg.dataDir;
        Environment = "PORT=${toString cfg.port}";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    users.users.home-tools = {
      isSystemUser = true;
      home = cfg.dataDir;
      createHome = true;
      shell = pkgs.zsh;
      group = cfg.group;
    };

    users.groups.home-tools = { };
  };
}
