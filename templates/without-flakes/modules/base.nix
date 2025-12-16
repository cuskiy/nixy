{ mkStr, ... }:
{
  modules.base = {
    target = "nixos";
    options = {
      hostName = mkStr null;
      user = mkStr null;
      timeZone = mkStr "UTC";
    };
    module =
      { node, ... }:
      {
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        networking.hostName = node.base.hostName;
        time.timeZone = node.base.timeZone;
        users.users.${node.base.user} = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          initialPassword = "changeme";
        };
        system.stateVersion = "24.11";
      };
  };
}
