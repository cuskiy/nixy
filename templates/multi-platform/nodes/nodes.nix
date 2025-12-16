{
  nodes.workstation = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "workstation";
    base.user = "alice";
    extraModules = [
      {
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        fileSystems."/boot" = {
          device = "/dev/disk/by-label/boot";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
      }
    ];
  };

  nodes.macbook = {
    system = "aarch64-darwin";
    darwin.enable = true;
    darwin.hostName = "macbook";
  };

  nodes."alice-home" = {
    system = "x86_64-linux";
    target = "home";
    home.enable = true;
    home.username = "alice";
  };
}
