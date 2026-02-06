{ mkStr, ... }:
{
  schema.home = {
    username = mkStr null;
    directory = mkStr "/home";
  };

  modules.home.load = [
    (
      { host, ... }:
      {
        home.username = host.home.username;
        home.homeDirectory = "${host.home.directory}/${host.home.username}";
        home.stateVersion = "26.05";
        programs.home-manager.enable = true;
      }
    )
  ];
}
