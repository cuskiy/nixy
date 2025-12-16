# Multi-platform Setup

Configure NixOS, Darwin, and Home Manager in one flake.

## flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
    nixy.url = "github:anialic/nixy";
  };

  outputs = { nixpkgs, nixy, ... }@inputs: nixy.mkFlake {
    inherit nixpkgs;
    imports = [ ./. ];
    args = { inherit inputs; };
  };
}
```

## targets.nix

```nix
{ inputs, nixpkgs, ... }:
{
  targets.darwin = {
    instantiate = { system, modules, specialArgs }:
      inputs.nix-darwin.lib.darwinSystem { inherit system modules specialArgs; };
    output = "darwinConfigurations";
  };

  targets.home = {
    instantiate = { system, modules, specialArgs }:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = modules;
        extraSpecialArgs = specialArgs;
      };
    output = "homeConfigurations";
  };
}
```

## Platform-specific Modules

```nix
# modules/base.nix - NixOS
{ mkStr, ... }:
{
  modules.base = {
    target = "nixos";
    options.hostName = mkStr null;
    module = { node, ... }: {
      networking.hostName = node.base.hostName;
    };
  };
}

# modules/darwin.nix
{ mkStr, ... }:
{
  modules.darwin = {
    target = "darwin";
    options.hostName = mkStr null;
    module = { node, ... }: {
      networking.hostName = node.darwin.hostName;
      system.stateVersion = 5;
    };
  };
}

# modules/home.nix
{ mkStr, ... }:
{
  modules.home = {
    target = "home";
    options.username = mkStr null;
    module = { node, ... }: {
      home.username = node.home.username;
      home.stateVersion = "24.11";
      programs.home-manager.enable = true;
    };
  };
}
```

## Nodes

```nix
# nodes/nodes.nix
{ inputs, ... }:
{
  nodes.workstation = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "workstation";
  };

  nodes.macbook = {
    system = "aarch64-darwin";
    darwin.enable = true;
    darwin.hostName = "macbook";
  };

  nodes."alice-home" = {
    system = "x86_64-linux";
    target = "home";
    home.enable = true;
    home.username = "alice";
  };
}
```
