{ mkStr, ... }:
{
  modules.darwin = {
    target = "darwin";
    options.hostName = mkStr null;
    module =
      { node, ... }:
      {
        networking.hostName = node.darwin.hostName;
        system.stateVersion = 5;
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
  };
}
