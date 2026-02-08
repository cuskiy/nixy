{ mkStr, ... }:
{
  schema.base = {
    hostName = mkStr null;
    user = mkStr null;
    timeZone = mkStr "UTC";
  };

  traits = [
    {
      name = "base";
      module =
        {
          conf,
          config,
          pkgs,
          ...
        }:
        {
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          networking.hostName = conf.base.hostName;
          time.timeZone = conf.base.timeZone;
          users.users.${conf.base.user} = {
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
        };
    }
  ];
}
