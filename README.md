<p align="center">
  <img src="https://raw.githubusercontent.com/anialic/nixy/main/.github/assets/logo.svg" width="200" alt="Nixy">
</p>

<p align="center">
  Lightweight NixOS/Darwin/Home Manager framework
</p>

<p align="center">
  <a href="https://anialic.github.io/nixy">Documentation</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#templates">Templates</a>
</p>

---

## Quick Start

```bash
nix flake init -t github:anialic/nixy#minimal
```

## Overview

Nixy organizes configurations around **hosts** (machines) and **modules** (features). Each host declares which modules it needs:

```nix
hosts.server = {
  system = "x86_64-linux";
  base.enable = true;
  base.hostName = "server";
};
```

Options are declared in `schema`, modules are loaded via `modules.*.load`:

```nix
{ mkStr, ... }:
{
  schema.base.hostName = mkStr null;

  modules.base.load = [({ host, ... }: {
    networking.hostName = host.base.hostName;
  })];
}
```

Only enabled modules are loaded. Disabled modules don't exist in the final configuration.

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixy.url = "github:anialic/nixy";
  };

  outputs = { nixpkgs, nixy, ... }@inputs: nixy.eval {
    inherit nixpkgs;
    imports = [ ./. ];
    args = { inherit inputs; };
  };
}
```

## Templates

| Template | Description |
|----------|-------------|
| `minimal` | Single NixOS machine |
| `complex` | Multi-platform with deploy-rs, custom targets, and assertions |

```bash
nix flake init -t github:anialic/nixy#<template>
```

## Built-in Commands

```bash
nix run .#check    # Show schema, modules, and hosts
```

## License

Apache-2.0
