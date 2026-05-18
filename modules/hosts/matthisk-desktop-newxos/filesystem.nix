_:
let
  # KINGSTON SNVS2000G (1.8T NVMe SSD) — replace with actual disk on reinstall.
  mainDisk = "/dev/disk/by-id/nvme-KINGSTON_SNVS2000G_50026B7282A10367";
  filesystemConfig = {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = mainDisk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              start = "1MiB";
              end = "1GiB";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "lvm_pv";
                  vg = "system";
                };
              };
            };
          };
        };
      };

      lvm_vg.system = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "16GiB";
            content = {
              type = "swap";
            };
          };

          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
in
{
  flake.modules.nixos.matthisk-desktop-newxos = filesystemConfig;
}
