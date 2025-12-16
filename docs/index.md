# Nixy

A minimal NixOS/Darwin/Home Manager framework.

## What is Nixy?

Nixy helps you organize NixOS configurations around **nodes** (machines) and **modules** (reusable features). Instead of managing complex module imports, you declare what each machine needs:

```nix
nodes.server = {
  system = "x86_64-linux";
  base.enable = true;
  ssh.enable = true;
};
```

## Key Features

- **Node-centric**: One node = one machine. All config in one place.
- **Conditional modules**: Only enabled modules are imported.
- **Type-safe**: Options on disabled modules throw errors.
- **Multi-platform**: NixOS, Darwin, and Home Manager support.
- **Dependency tracking**: Modules can declare requirements.

## Quick Start

```bash
nix flake init -t github:anialic/nixy#minimal
```

Then edit `nodes/` and `modules/` to match your setup.
