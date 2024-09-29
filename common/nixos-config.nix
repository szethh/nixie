{ config, pkgs, ... }:

{
  imports = [ ./szeth.nix ];

  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "24.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # this helps for systems with low disk space
  boot.tmp.useTmpfs = true;

  networking.nameservers = [ "1.1.1.1" ];

  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "${config.deployment.keys.age.destDir}/age";

  ### DEPLOYMENT ###
  deployment = {
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = {
      age = {
        keyFile = "/Users/szeth/.config/sops/age/keys.txt";
        # if left unspecified, the key will be stored in /run/keys
        # which is in ramfs, so it gets cleared on reboot
        # this means that after rebooting, the key is lost and so are the secrets
        # which means that all our services stop working...
        # https://github.com/Mic92/sops-nix/issues/149
        destDir = "/etc/keys";
      };
    };
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    # Daily 00:00
    dates = "daily UTC";
  };

  nix.gc = {
    automatic = true;
    # Every Monday 01:00 (UTC)
    dates = "Monday 01:00 UTC";
    options = "--delete-older-than 7d";
  };

  # Run garbage collection whenever there is less than 500MB free space left
  nix.extraOptions = ''
    min-free = ${toString (500 * 1024 * 1024)}
  '';

  ## Optional: Clear >1 month-old logs
  systemd = {
    services.clear-log = {
      description = "Clear >1 month-old logs every week";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=30d";
        ExecStartPost = "${pkgs.systemd}/bin/journalctl --vacuum-size=500M";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "weekly UTC";
    };
  };

  users.mutableUsers = false;
  # initialHashedPassword or hashedPassword?
  users.users.root.initialHashedPassword = "*";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgnIn7uXqucLjBn3fcJtRoeTVtpAIs/vFub8ULiud1f szeth@mackie.local"
  ];

  services.openssh.enable = true;
  services.tailscale.enable = true;
}
