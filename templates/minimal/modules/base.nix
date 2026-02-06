{ mkStr, ... }:
{
  schema.base = {
    hostName = mkStr null;
    user = mkStr null;
    timeZone = mkStr "UTC";
  };

  modules.base.load = [
    (
      { host, ... }:
      {
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        networking.hostName = host.base.hostName;
        time.timeZone = host.base.timeZone;
        users.users.${host.base.user} = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          initialPassword = "changeme";
        };
        system.stateVersion = "26.05";
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      }
    )
  ];
}
