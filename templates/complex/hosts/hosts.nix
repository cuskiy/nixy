{
  hosts.server = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "server";
    base.user = "admin";
    deploy.enable = true;
    deploy.hostname = "192.168.1.100";
    deploy.sshUser = "deploy";
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
        services.openssh.enable = true;
      }
    ];
  };

  hosts.macbook = {
    system = "aarch64-darwin";
    darwin.enable = true;
    darwin.hostName = "macbook";
  };

  hosts."alice-home" = {
    system = "x86_64-linux";
    target = "home";
    home.enable = true;
    home.username = "alice";
  };
}
