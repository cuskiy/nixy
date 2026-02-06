{ mkStr, inputs, ... }:
{
  schema.disko.device = mkStr null;

  modules.disko.load = [
    inputs.disko.nixosModules.disko
    ({ host, ... }: {
      disko.devices.disk.main = {
        device = host.disko.device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    })
  ];
}
