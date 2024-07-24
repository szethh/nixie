{
  config,
  lib,
  pkgs,
  disko,
  ...
}:

{
  imports = [ ../../common/nixos-config.nix ];

  # UNCOMMENT ME WHEN GENERATING THE VM IMAGE
  # followed this guide https://nixos.wiki/wiki/Proxmox_Virtual_Environment
  # nix run github:nix-community/nixos-generators -- --format proxmox --configuration hosts/{{host}}/proxmox.nix
  #   proxmox.qemuConf = {
  #     diskSize = lid.mkForce "41160";
  #     virtio0 = "tank-store:vm-505-disk-0";
  #     memory = 4098;
  #     cores = 2;
  #     name = "nixvm";
  #   };

  # cloudInit disables the hostname
  # but only in unstable
  # we are using 24.05, cloudInit is not available
  # proxmox.cloudInit.enable = false;

  # okay so this was a big hassle to get working
  # ended up just copying this (it's what was used to generate the image in the first place)
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/virtualisation/proxmox-image.nix
  boot = {
    growPartition = true;
    kernelParams = [ "console=ttyS0" ];
    loader.grub = {
      device =
        # Even if there is a separate no-fs partition ("/dev/disk/by-partlabel/no-fs" i.e. "/dev/vda2"),
        # which will be used the bootloader, do not set it as loader.grub.device.
        # GRUB installation fails, unless the whole disk is selected.
        "/dev/vda";
    };

    loader.timeout = 0;
    initrd.availableKernelModules = [
      "uas"
      "virtio_blk"
      "virtio_pci"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  services.qemuGuest.enable = true;

  networking = {
    hostName = "nixvm";
    defaultGateway = "192.168.50.1";

    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "192.168.50.44";
          prefixLength = 24;
        }
      ];
      useDHCP = false;
    };
  };
}
