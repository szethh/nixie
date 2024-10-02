{
  modulesPath,
  lib,
  name,
  pkgs,
  config,
  disko,
  ...
}:

{
  imports = [
    # not sure what this does
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  disko.devices = import ./disks.nix;

  system.stateVersion = "24.05";

  boot.swraid.enable = true;

  # Specify the devices to install the boot loader to.
  boot.loader.grub = {
    enable = true;
    # for some reason using just /sda or /sdb does not work with efiSupport = false
    # hetzner is legacy bios, so we need to set it to false
    # and also it seems that we need to leave it empty
    # i think disko is doing this for us
    # but if we don't specify devices or mirroredBoots it doesn't work
    # and if we do specify them we fail an assertion since they are duplicated (added by disko)
    devices = [
      #   "/dev/disk/by-partlabel/disk-_dev_sda"
      #   "/dev/disk/by-partlabel/disk-_dev_sdb"
    ];
    copyKernels = true;
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
  boot.initrd.systemd.network.networks."10-uplink" = config.systemd.network.networks."10-uplink";
  # networking.firewall.logRefusedConnections = false;
}
