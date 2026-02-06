{
  hosts.server = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "server";
    base.user = "admin";
    disko.enable = true;
    disko.device = "/dev/sda";
    deploy.hostname = "192.168.1.100";
    deploy.sshUser = "deploy";
    extraModules = [
      { services.openssh.enable = true; }
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
