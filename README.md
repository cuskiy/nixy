<p align="center">
  <img src="https://raw.githubusercontent.com/cuskiy/nixy/main/.github/assets/logo.svg" width="200" alt="nixy">
</p>

<p align="center">
  Module builder for Nix.
</p>

<p align="center">
  <a href="https://cuskiy.github.io/nixy">Documentation</a> ·
  <a href="#quick-start">Quick Start</a>
</p>

---

## Quick Start

```bash
nix flake init -t github:cuskiy/nixy#minimal
```

## Overview

nixy separates **what knobs exist** (schema), **what they do** (traits), and **which target gets what** (nodes).

Define schema and traits:

```nix
{ mkStr, mkPort, ... }:
{
  schema.ssh.port = mkPort 22;

  traits.ssh = { schema, ... }: {
    services.openssh.enable = true;
    services.openssh.ports = [ schema.ssh.port ];
  };
}
```

Define nodes:

```nix
{
  nodes.server = {
    traits = [ "base" "ssh" ];
    schema.base.system = "x86_64-linux";
    schema.ssh.port = 2222;
  };
}
```

Wire into your flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixy.url = "github:cuskiy/nixy";
  };

  outputs = { nixpkgs, nixy, ... }@inputs:
    let
      lib = nixpkgs.lib;
      cluster = nixy.eval {
        inherit lib;
        imports = [ ./. ];
        args = { inherit inputs; };
      };
    in {
      nixosConfigurations = lib.mapAttrs (_: node:
        lib.nixosSystem {
          system = node.schema.base.system;
          modules = [ node.module ];
        }
      ) cluster.nodes;
    };
}
```

## License

Apache-2.0
