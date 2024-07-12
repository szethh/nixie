{ modulesPath, lib, name, pkgs, config, ... }:

{
  imports = [
    # not sure what this does
    "${modulesPath}/installer/scan/not-detected.nix"
    ../../common/szeth.nix
  ];

  disko.devices = import ./disks.nix;

  # sops.defaultSopsFile = ../../secrets/secrets.yaml;
  # sops.age.keyFile = "${config.deployment.keys.age.destDir}/age";
  # sops.secrets = {
  #   
  # };

  system.stateVersion = "24.05";

  deployment = {
    targetHost = "<ip>";
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = { age = { keyFile = "/Users/szeth/.config/sops/age/keys.txt"; }; };
  };

  programs.zsh.enable = true;

  # networking.hostName = name;

  # services.tailscale.enable = true;

  # what even is this
  # boot.loader.grub = {
  #   copyKernels = true;
  #   devices = [ "/dev/sda" "/dev/sdb" ];
  #   efiInstallAsRemovable = true;
  #   efiSupport = true;
  #   enable = true;
  #   fsIdentifier = "uuid";
  #   version = 2;
  # };
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
