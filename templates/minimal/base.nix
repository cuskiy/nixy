{ mkStr, ... }:
{
  schema.base = {
    hostName = mkStr null;
    user = mkStr null;
    timeZone = mkStr "UTC";
    password = mkStr "changeme";
  };

  traits = [
    {
      name = "base";
      module =
        { conf, ...}: { config, pkgs, ... }:
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
            password = conf.base.password;
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
