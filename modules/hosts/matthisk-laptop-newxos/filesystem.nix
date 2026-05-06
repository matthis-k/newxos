{ ... }:
let
  mainDisk = "/dev/disk/by-id/ata-SAMSUNG_SSD_PM871b_M.2_2280_256GB_S3U0NE0JB62490";
in
{
  flake.modules.nixos.matthisk-laptop-newxos = {
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
}
