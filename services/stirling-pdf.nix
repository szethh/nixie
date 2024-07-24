{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.stirling-pdf;

  # function to format environment variables
  formatEnv = envVars: concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${v}") envVars);

  envFileContent = formatEnv cfg.environment;

  # this actually creates the .env file
  envFile = pkgs.writeText ".env" envFileContent;
in
{
  options = {
    services.stirling-pdf = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Stirling PDF service.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.stirling-pdf;
        description = "The package to use.";
      };

      user = mkOption {
        type = types.str;
        default = "stirling-pdf";
        description = "The user to run the service as.";
      };

      group = mkOption {
        type = types.str;
        default = "stirling-pdf";
        description = "The group to run the service as.";
      };

      directory = mkOption {
        type = types.path;
        default = "/var/lib/stirling-pdf";
        description = "The directory to store the data in.";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional arguments to pass to Stirling PDF.";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables to pass to the Stirling PDF service.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.stirling-pdf = {
      description = "Stirling PDF";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        # create the .env file before starting the service
        # ExecStartPre = "${envFile}";

        ExecStart = "${cfg.package}/bin/Stirling-PDF ${concatStringsSep " " cfg.extraArgs}";
        ExecStop = "/bin/kill -15 $MAINPID";

        Restart = "always";
        RestartSec = 10;

        WorkingDirectory = "${cfg.directory}";
        EnvironmentFile = "${envFile}";

        SuccessExitStatus = 143;

        User = cfg.user;
        Group = cfg.group;
      };
    };

    systemd.tmpfiles.rules = [ "d '${cfg.directory}' 0755 ${cfg.user} ${cfg.group} - -" ];

    users.groups = mkIf (cfg.group == "stirling-pdf") { stirling-pdf = { }; };

    users.users = mkIf (cfg.user == "stirling-pdf") {
      stirling-pdf = {
        description = "Stirling PDF Service";
        home = cfg.directory;
        useDefaultShell = true;
        group = cfg.group;
        isSystemUser = true;
      };
    };
  };

  meta = {
    maintainers = with maintainers; [ szethh ];
  };
}
