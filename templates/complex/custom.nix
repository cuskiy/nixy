{
  lib,
  config,
  inputs,
  ...
}:
let
  deployHosts = lib.filterAttrs (_: h: h.deploy.hostname != null) config.hosts;
in
{
  flake.deploy.nodes = lib.mapAttrs (
    name: host:
    let
      cfg = config.flake.nixosConfigurations.${name};
    in
    {
      hostname = host.deploy.hostname;
      sshUser = host.deploy.sshUser;
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.${host.system}.activate.nixos cfg;
      };
    }
  ) deployHosts;

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-rfc-style;
    };

  rules = [
    {
      assertion = config.hosts ? server;
      message = "a 'server' host must be defined";
    }
  ];
}
