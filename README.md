<p align="center">
  <img src="https://raw.githubusercontent.com/anialic/nixy/main/.github/assets/logo.svg" width="200" alt="Nixy">
</p>

<p align="center">
  A minimal NixOS/Darwin/Home Manager framework
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

Nixy organizes your NixOS configuration around **nodes** (machines) and **modules** (features). Each node declares which modules it needs:

```nix
nodes.server = {
  system = "x86_64-linux";
  base.enable = true;
  base.hostName = "server";
  ssh.enable = true;
};
```

Only enabled modules are imported. Disabled modules don't exist in the final configuration.

## Usage

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixy.url = "github:anialic/nixy";

  outputs = { nixpkgs, nixy, ... }@inputs: nixy.mkFlake {
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
| `multi-platform` | NixOS + Darwin + Home Manager |
| `deploy-rs` | Remote deployment with deploy-rs |
| `without-flakes` | Traditional non-flake setup |

```bash
nix flake init -t github:anialic/nixy#<template>
```

## Built-in Commands

```bash
nix run .#allOptions     # List modules and options
nix run .#allNodes       # List nodes
nix run .#checkOptions   # Verify option defaults
```

## License

Apache-2.0
