{ mkStr, ... }:
{
  schema.darwin.hostName = mkStr null;

  modules.darwin.load = [
    (
      { host, ... }:
      {
        networking.hostName = host.darwin.hostName;
        system.stateVersion = 6;
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      }
    )
  ];
}
