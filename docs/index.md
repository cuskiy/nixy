# Nixy

Lightweight NixOS/Darwin/Home Manager framework.

## What is Nixy?

Nixy organizes NixOS configurations around **hosts** (machines) and **modules** (features). Options are declared in `schema`, implementation goes in `modules.*.load`:

```nix
hosts.server = {
  system = "x86_64-linux";
  base.enable = true;
  base.hostName = "server";
};
```

## Key Features

- **Host-centric**: One host = one machine. All config in one place.
- **Schema/module split**: Declare options in `schema`, load NixOS modules in `modules.*.load`.
- **Multi-platform**: NixOS, Darwin, and Home Manager via custom targets.
- **Composable**: Multiple files contribute to the same schema and modules via deep merge.
- **Lightweight**: No dependencies beyond nixpkgs.

## Quick Start

```bash
nix flake init -t github:anialic/nixy#minimal
```

Then edit `modules/` and `hosts/` to match your setup.
