{ mkStr, ... }:
{
  modules.base = {
    target = "nixos";
    options = {
      hostName = mkStr null;
      timeZone = mkStr "UTC";
    };
    module =
      { node, ... }:
      {
        networking.hostName = node.base.hostName;
        time.timeZone = node.base.timeZone;
        system.stateVersion = "24.11";
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
  };
}
