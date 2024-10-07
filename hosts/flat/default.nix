{
  modulesPath,
  lib,
  name,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./misc.nix
    ./vm.nix
    ../../common/nixos-config.nix
    ../../services/borgir.nix
  ];

  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  # systemd.targets.sleep.enable = false;
  # systemd.targets.suspend.enable = false;
  # systemd.targets.hibernate.enable = false;
  # systemd.targets.hybrid-sleep.enable = false;
  # powerManagement.enable = false;

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  ### BORG ###
  services.borgir = {
    enable = true;
    repoId = "a03vajw3";
    paths = [
      "/var/lib"
      "/srv/vm/images"
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    virt-manager
    usbutils
    rustdesk
    virt-viewer
  ];

  networking.firewall.enable = false;
  networking.defaultGateway = "192.168.50.1";
  networking.bridges.br0.interfaces = [ "eno1" ];
  networking.interfaces.br0 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.50.12";
        prefixLength = 24;
      }
    ];
  };

}
