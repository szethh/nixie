{ config, lib, pkgs, ... }:

with lib;

let quartzPkg = import ../packages/quartz.nix { inherit pkgs; };
in {
  options = {
    services.quartz = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Quartz service.";
      };

      directory = mkOption {
        type = types.path;
        default = "content";
        description = "The content folder.";
      };

      output = mkOption {
        type = types.path;
        default = "public";
        description = "The output folder.";
      };

      port = mkOption {
        type = types.int;
        default = 8080;
        description = "The port to run the local preview server on.";
      };

      concurrency = mkOption {
        type = types.int;
        default = 1;
        description = "The number of threads to use to parse notes.";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "-v or --verbose" ];
        description = "Additional arguments to pass to Quartz.";
      };
    };
  };

  config = mkIf config.services.quartz.enable {
    systemd.services.quartz = {
      description = "Quartz Static Site Generator";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart =
          "${quartzPkg}/bin/quartz build --serve --directory ${config.services.quartz.directory} --output ${config.services.quartz.output} --port ${
            toString config.services.quartz.port
          } --concurrency ${toString config.services.quartz.concurrency} ${
            concatStringsSep " " config.services.quartz.extraArgs
          }";
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
