{ mkStr, ... }:
{
  schema.base = {
    system = mkStr "x86_64-linux";
    hostName = mkStr null;
    user = mkStr null;
    timeZone = mkStr "UTC";
  };

  traits.a =
    {
      schema,
      config,
      pkgs,
      ...
    }:
    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      networking.hostName = schema.base.hostName;
      time.timeZone = schema.base.timeZone;
      users.users.${schema.base.user} = {
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
