{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  vmImagesPath = "/srv/vm/images";

  # ideally this could come from nixvirt
  vms = [ "hass" ];
in
{
  imports = [ inputs.nixvirt.nixosModules.default ];

  virtualisation = {
    libvirtd = {
      enable = true;
      # Used for UEFI boot of Home Assistant OS guest image
      qemu = {
        ovmf.enable = true;
        package = pkgs.qemu_kvm;
      };
    };
  };

  virtualisation.libvirt = {
    enable = true;
    connections."qemu:///system" = {
      domains = [
        {
          definition = ./vm/haos.xml;
          #   definition = inputs.nixvirt.lib.domain.writeXML (
          #     inputs.nixvirt.lib.domain.templates.linux {
          #       name = "hass";
          #       uuid = "cc7439ed-36af-4696-a6f2-1f0c4474d87e";
          #       memory = {
          #         count = 4;
          #         unit = "GiB";
          #       };
          #       storage_vol = "${vmImagesPath}/haos_ova-13.1.qcow2";
          #       #  {
          #       #   pool = "ha_pool";
          #       #   volume = "${vmImagesPath}/haos_ova-13.1.qcow2";
          #       # };
          #     }
          #     // {
          #       vcpu = {
          #         placement = "static";
          #         count = 2;
          #       };
          #     }
          #   );
          active = true;
        }
      ];

      #   networks = [
      #     {
      #       #   definition = inputs.nixvirt.lib.network.writeXML (
      #       #     inputs.nixvirt.lib.network.templates.bridge {
      #       #       name = "bridged-network";
      #       #       bridge_name = "br0";
      #       #       uuid = "70b08691-28dc-4b47-90a1-45bbeac9ab5a";
      #       #       subnet_byte = 50;
      #       #     }
      #       #   );
      #       definition = ./vm/network.xml;
      #       active = true;
      #     }
      #   ];
    };
  };

  # used this as a guide
  # https://github.com/Nozzie/kvm-borg-backup/blob/main/kvm-backup.sh
  services.borgbackup.jobs.borgbase = {
    readWritePaths = [ vmImagesPath ];
    # VM SNAPSHOTS
    preHook = ''
      for VM_NAME in ${lib.concatStringsSep " " vms}; do
        SNAPSHOT_NAME="$VM_NAME-snapshot"
        echo "Creating snapshot for VM: $VM_NAME..."
        
        ${pkgs.libvirt}/bin/virsh snapshot-create-as --domain "$VM_NAME" tmp-ext-snap-"$SNAPSHOT_NAME" ''${DISKSPEC_ARR[*]} --disk-only --atomic
      done
    '';

    postHook = ''
      for VM_NAME in ${lib.concatStringsSep " " vms}; do
        SNAPSHOT_NAME="$VM_NAME-snapshot"

        echo "Merging snapshot back to base image..."
        DISK_NAMES=($(${pkgs.libvirt}/bin/virsh domblklist "$VM_NAME" | grep -e vd -e sd | grep -e '/' | ${pkgs.gawk}/bin/gawk '{print $1}'))
        echo "Disks to merge: $DISK_NAMES"
        for DISK_NAME in "''${DISK_NAMES[@]}"; do
            echo "merging $DISK_NAME" into "$VM_NAME"
            ${pkgs.libvirt}/bin/virsh blockcommit "$VM_NAME" "$DISK_NAME" --active --pivot
        done

        echo "Deleting snapshot: $SNAPSHOT_NAME..."
        ${pkgs.libvirt}/bin/virsh snapshot-delete "$VM_NAME" --snapshotname tmp-ext-snap-"$SNAPSHOT_NAME" --metadata
        rm ${vmImagesPath}/*.tmp-ext-snap-"$SNAPSHOT_NAME"
      done
    '';
  };
}
