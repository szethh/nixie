{ modulesPath, lib, name, pkgs, config, ... }:

{
  imports = [
    # not sure what this does
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  disko.devices = import ./disks.nix;

  system.stateVersion = "24.05";

  networking.hostName = name;

  boot.swraid.enable = true;

  # Specify the devices to install the boot loader to.
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda1" "/dev/sdb1" ];
    efiSupport = true;
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    # SATA SSDs/HDDs
    "sd_mod"
    # NVME
    # "nvme"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelModules = [ "kvm-intel" ];

  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.usePredictableInterfaceNames = false;

  # from https://github.com/nix-community/nixos-anywhere/issues/110
  systemd.network.networks."10-uplink" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "ipv4";
    # hetzner requires static ipv6 addresses
    networkConfig.Gateway = "fe80::1";
    # not interested in ipv6 for now
    # networkConfig.Address = "";

    networkConfig.IPv6AcceptRA = "no";
  };
  boot.initrd.systemd.network.networks."10-uplink" =
    config.systemd.network.networks."10-uplink";
  networking.nameservers = [ "1.1.1.1" ];
  # networking.firewall.logRefusedConnections = false;

  users.users.root.initialHashedPassword = "*";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgnIn7uXqucLjBn3fcJtRoeTVtpAIs/vFub8ULiud1f szeth@mackie.local"
  ];

  services.openssh.enable = true;
}
