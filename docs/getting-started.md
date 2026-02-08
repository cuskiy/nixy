# Getting Started

## Install

```bash
nix flake init -t github:anialic/nixy#minimal
```

This creates a working NixOS configuration with three files:

- `flake.nix` — wires nixy into `nixosConfigurations`
- `base.nix` — declares schema options and a `base` trait
- `my-nixos.nix` — defines a node that uses the `base` trait

## Build

```bash
nix build .#nixosConfigurations.my-nixos.config.system.build.toplevel
```

## How It Works

`nixy.eval lib { ... }` scans your directory for `.nix` files, collects all schema declarations, traits, and node definitions, then produces one NixOS-compatible module per node.

```
your-config/
├── flake.nix          # calls nixy.eval
├── base.nix           # schema + traits
├── ssh.nix            # schema + traits
└── my-nixos.nix       # node definition
```

Each file can contribute `schema`, `traits`, `nodes`, and `rules`. Everything is merged automatically.

## Next Steps

- [Guide](/guide) — full walkthrough of schema, traits, nodes, and rules
- [Helpers](/helpers) — reference for `mkStr`, `mkBool`, `mkModule`, etc.
- [API](/api) — `nixy.eval` parameters and return shape
