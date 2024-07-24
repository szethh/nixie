{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.borgir;
  opts = options.services.borgir;
in
{
  options.services.borgir = {
    enable = mkEnableOption "borgir";

    jobName = mkOption {
      type = types.str;
      default = "borgbase";
      description = "Name of the borgbackup job.";
    };

    paths = mkOption {
      type = types.listOf types.path;
      default = [ "/var/lib" ];
      description = "Paths to back up.";
    };

    exclude = mkOption {
      type = types.listOf types.path;
      default = [ "/var/lib/systemd" ];
      description = "Paths to exclude from the backup.";
    };

    repoId = mkOption {
      type = types.str;
      description = "Repository/user ID for the borgbase repository.";
    };

    BORG_RSH = mkOption {
      type = types.str;
      default = "ssh -i /root/borgbackup/ssh_key";
      description = "SSH command to use for borgbackup.";
    };
  };

  # thanks xe this was helpful
  # https://xeiaso.net/blog/borg-backup-2021-01-09/
  config = mkIf cfg.enable {
    sops.secrets.BORG_PASSPHRASE.owner = "root";

    services.borgbackup.jobs.${cfg.jobName} = {
      paths = cfg.paths;
      exclude = cfg.exclude;

      repo = "${cfg.repoId}@${cfg.repoId}.repo.borgbase.com:repo";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.BORG_PASSPHRASE.path}";
      };

      # we have to create the ssh key manually on first run
      # ssh-keygen -f /root/borgbackup/ssh_key -t ed25519
      # also you gotta trust the host: ssh -i /root/borgbackup/ssh_key repoId@repoId.repo.borgbase.com
      environment.BORG_RSH = cfg.BORG_RSH;
      compression = "auto,lzma";
      startAt = "daily";
      prune.keep = {
        within = "1d";
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
    };
  };
}
