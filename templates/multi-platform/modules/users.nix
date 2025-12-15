{ mkStr, ... }:
{
  modules.base.options.user = mkStr null;
  modules.base.module =
    { node, ... }:
    {
      users.users.${node.base.user} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        initialPassword = "changeme";
      };
    };
}
