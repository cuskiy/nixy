{ mkStr, ... }:
{
  modules.deploy = {
    options = {
      hostname = mkStr null;
      sshUser = mkStr "root";
    };
  };
}
