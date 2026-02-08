<p align="center">
  <img src="https://raw.githubusercontent.com/anialic/nixy/main/.github/assets/logo.svg" width="200" alt="Nixy">
</p>

<p align="center">
  Schema-driven configuration framework for NixOS, Darwin, and Home Manager
</p>

<p align="center">
  <a href="https://anialic.github.io/nixy">Documentation</a> ·
  <a href="#quick-start">Quick Start</a>
</p>

---

## Quick Start

```bash
nix flake init -t github:anialic/nixy#minimal
```

## Overview

Nixy separates **what knobs exist** (schema), **what they do** (traits), and **which machine gets what** (nodes).

Define schema and traits:

```nix
{ mkStr, mkPort, ... }:
{
  schema.ssh.port = mkPort 22;

  traits = [{
    name = "ssh";
    module = { conf, ... }: { config, ... }: {
      services.openssh.enable = true;
      services.openssh.ports = [ conf.ssh.port ];
    };
  }];
}
```

Define nodes:

```nix
{
  nodes.server = {
    meta.system = "x86_64-linux";
    traits = [ "base" "ssh" ];
    schema.ssh.port = 2222;
  };
}
```

Wire into your flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixy.url = "github:anialic/nixy";
  };

  outputs = { nixpkgs, nixy, ... }@inputs:
    let
      lib = nixpkgs.lib;
      cluster = nixy.eval lib {
        imports = [ ./. ];
        args = { inherit inputs; };
      };
    in {
      nixosConfigurations = lib.mapAttrs (_: node:
        lib.nixosSystem {
          system = node.meta.system;
          modules = [ node.module ];
        }
      ) cluster.nodes;
    };
}
```

## License

Apache-2.0
