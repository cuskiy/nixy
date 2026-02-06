{ mkStr, ... }:
{
  schema.deploy = {
    hostname = mkStr null;
    sshUser = mkStr "root";
  };

  modules.deploy.load = [ ];
}
