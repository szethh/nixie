{ lib, ... }:
{
  disk = lib.genAttrs [ "/dev/sda" "/dev/sdb" ]
    (disk: {
      type = "disk";
      device = disk;
      content = {
        type = "gpt";
        partitions = {
          # boot = {
          #   start = "0";
          #   end = "1M";
          #   part-type = "primary";
          #   type = "EF02";
          #   priority = 1;
          # };
          ESP = {
            # start = "1M";
            size = "512M";
            type = "EF00";
            content = {
              type = "mdraid";
              name = "boot";
              # type = "filesystem";
              # format = "vfat";
              # mountpoint = "/boot";
            };
            priority = 1;
          };
          nixos = {
            # start = "1GiB";
            size = "100%";
            content = {
              type = "mdraid";
              name = "nixos";
            };
            priority = 2;
          };
        };
      };
    });
  mdadm = {
    boot = {
      type = "mdadm";
      level = 1;
      metadata = "1.0";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
      };
    };
    nixos = {
      type = "mdadm";
      level = 1;
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };
}