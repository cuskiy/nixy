{ mkStr, ... }:
{
  modules.home = {
    target = "home";
    options = {
      username = mkStr null;
      directory = mkStr "/home";
    };
    module =
      { node, ... }:
      {
        home.username = node.home.username;
        home.homeDirectory = "${node.home.directory}/${node.home.username}";
        home.stateVersion = "24.11";
        programs.home-manager.enable = true;
      };
  };
}
