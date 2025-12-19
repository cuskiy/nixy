# Getting Started

## Installation

Initialize a new project from a template:

```bash
nix flake init -t github:anialic/nixy#minimal
```

Available templates:
- `minimal` - Single NixOS machine
- `multi-platform` - NixOS + Darwin + Home Manager
- `deploy-rs` - Remote deployment
- `without-flakes` - Traditional setup

## Project Structure

```
my-config/
├── flake.nix
├── modules/
│   └── base.nix
└── nodes/
    └── my-machine.nix
```

## Basic Configuration

**flake.nix**
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

**modules/base.nix**
```nix
{ mkStr, ... }:
{
  modules.base = {
    target = "nixos";
    options.hostName = mkStr null;
    module = { node, ... }: {
      networking.hostName = node.base.hostName;
      system.stateVersion = "24.11";
    };
  };
}
```

**nodes/my-machine.nix**
```nix
{
  nodes.my-machine = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "my-machine";
  };
}
```

## Building

```bash
nixos-rebuild switch --flake .#my-machine
```
