# Deploy-rs Integration

Remote deployment with deploy-rs.

## flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    nixy.url = "github:anialic/nixy";
  };

  outputs = { nixpkgs, nixy, ... }@inputs: nixy.mkFlake {
    inherit nixpkgs;
    imports = [ ./. ];
    args = { inherit inputs; };
  };
}
```

## modules/deploy.nix

```nix
{ mkStr, ... }:
{
  modules.deploy = {
    options = {
      hostname = mkStr null;
      sshUser = mkStr "root";
    };
  };
}
```

## custom.nix

```nix
{ lib, config, inputs, ... }:
let
  deployNodes = lib.filterAttrs (_: n: n.deploy.enable or false) config.nodes;
in {
  flake.deploy.nodes = lib.mapAttrs (name: node:
    let cfg = config.flake.nixosConfigurations.${name};
    in {
      hostname = node.deploy.hostname;
      sshUser = node.deploy.sshUser;
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.${node._system}.activate.nixos cfg;
      };
    }
  ) deployNodes;
}
```

## nodes/server.nix

```nix
{
  nodes.server = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "server";
    deploy.enable = true;
    deploy.hostname = "192.168.1.100";
    deploy.sshUser = "deploy";
  };
}
```

## Deployment

```bash
nix run github:serokell/deploy-rs -- .#server
```
