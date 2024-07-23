{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.megacmd;
  opt = options.services.megacmd;
in {
  options.services.megacmd = {
    enable = mkEnableOption "MEGAcmd sync service";

    package = mkPackageOption pkgs "megacmd" { };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/megacmd";
      description = "Path to MEGAcmd data directory";
    };

    syncPaths = mkOption {
      type = types.listOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable or disable syncing this path";
          };
          localPath = mkOption { type = types.path; };
          remotePath = mkOption { type = types.str; };
        };
      });
      default = [ ];
      description = "List of paths to sync with MEGAcmd";
      example = [{
        enable = true;
        localPath = "/path/to/local";
        remotePath = "/path/to/remote";
      }];
    };

    usernameFile = mkOption {
      type = types.path;
      description = "Path to MEGA account username file";
    };

    passwordFile = mkOption {
      type = types.path;
      description = "Path to MEGA account password file";
    };

    totpSecretFile = mkOption {
      type = types.nullOr types.path;
      description = "Path to MEGA account TOTP secret file";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.megacmd-sync = {
      description = "MEGAcmd Sync Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = let
          megaLoginScript = pkgs.writeShellScript "mega-login.sh" ''
            #!/bin/bash

            # Generate TOTP code if secret file is provided
            if [ -n "${cfg.totpSecretFile}" ]; then
              AUTH_CODE="--auth-code=$(${pkgs.oath-toolkit}/bin/oathtool --totp -b $(cat ${cfg.totpSecretFile}))"
            else
              AUTH_CODE=""
            fi

            # Execute login command
            LOGIN_CMD="${pkgs.megacmd}/bin/mega-exec login $(cat ${cfg.usernameFile}) $(cat ${cfg.passwordFile}) $AUTH_CODE"
            LOGIN_OUTPUT=$($LOGIN_CMD 2>&1) # Capture both stdout and stderr

            # login command is not idempotent
            # if we are already logged in, it will return "Already logged in" and fail
            if echo "$LOGIN_OUTPUT" | grep -q "Already logged in"; then
                echo "Already logged in. This is considered a successful login."
            else
                echo "$LOGIN_OUTPUT"
                exit 1
            fi
          '';
        in "${megaLoginScript}";

        ExecStart = let
          megaSyncScript = pkgs.writeShellScript "mega-sync.sh" ''
            #!/bin/bash

            # 1. Remove old sync paths
            # 1.1 get list of existing sync paths
            EXISTING_PATHS=$(${pkgs.megacmd}/bin/mega-exec sync --path-display-size=100 | ${pkgs.gawk}/bin/gawk '{if (NR>1) print $1, $2, $3}')
            # 1.2 remove all sync paths that are not in cfg.syncPaths
            # for now we just remove all sync paths
            # then recreate them
            while IFS= read -r line; do
                echo "Existing sync path: $line"
                ID=$(echo "$line" | ${pkgs.gawk}/bin/gawk '{print $1}')
                LOCAL_PATH=$(echo "$line" | ${pkgs.gawk}/bin/gawk '{print $2}')
                REMOTE_PATH=$(echo "$line" | ${pkgs.gawk}/bin/gawk '{print $3}')
                echo "Removing sync path with ID $ID: $LOCAL_PATH -> $REMOTE_PATH"
                # ids may start with hyphens
                ${pkgs.megacmd}/bin/mega-exec sync -d -- $ID
            done <<< "$EXISTING_PATHS"

            # 2. Create missing directories
            ${concatStringsSep "\n"
            (map (syncPath: "mkdir -p ${syncPath.localPath}") cfg.syncPaths)}

            # 3. Create provided sync paths
            ${concatStringsSep "\n" (map (syncPath:
              # here we use mega-exec {command_name} instead of mega-* because for some reason the package is broken
              # mega-sync (for example) is just a wrapper around mega-exec sync
              # if it was ./mega-exec sync, then it would work (they are in the same directory)
              # but it tries to find the mega-exec binary in PATH
              "${pkgs.megacmd}/bin/mega-exec sync ${syncPath.localPath} ${syncPath.remotePath}")
              cfg.syncPaths)}

            # 4. Enable/disable sync paths
            ${concatStringsSep "\n" (map (syncPath:
              let syncFlag = if syncPath.enable then "-r" else "-s";
              in "${pkgs.megacmd}/bin/mega-exec sync ${syncFlag} ${syncPath.localPath}")
              cfg.syncPaths)}
          '';
        in "${megaSyncScript}";
        Type = "oneshot";
        User = "mega";
        Group = "mega";
      };
    };

    users.users.mega = {
      isSystemUser = true;
      home = cfg.dataDir;
      createHome = true;
      shell = pkgs.zsh;
      group = "mega";
    };

    users.groups.mega = { };

    environment.systemPackages = with pkgs; [ gawk oath-toolkit ];
  };
}
