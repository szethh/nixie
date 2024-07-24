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
