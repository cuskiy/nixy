# Guide

nixy organizes configuration around three concepts: **schema** declares options, **traits** implement behavior, and **nodes** define targets.

## Schema

Declare options with helpers like `mkStr` and `mkPort`. Multiple files can contribute to the same schema tree — they are deep-merged.

```nix
{ mkStr, mkPort, mkBool, ... }:
{
  schema.ssh = {
    port = mkPort 22;
    permitRoot = mkBool false;
  };

  schema.base = {
    system = mkStr "x86_64-linux";
    hostName = mkStr null;
  };
}
```

All helpers wrap their type in `nullOr`, so every option accepts `null`. See [Helpers](/helpers) for the full list.

## Traits

A trait is a named behavior unit. The key is the trait name, the value is a module (function, attrset, or path).

```nix
traits.ssh = { schema, config, pkgs, ... }: {
  services.openssh = {
    enable = true;
    ports = [ schema.ssh.port ];
    settings.PermitRootLogin =
      if schema.ssh.permitRoot then "yes" else "no";
  };
};
```

## Nodes

Each node represents a target. It has three fields:

```nix
{
  nodes.server = {
    traits = [ "base" "ssh" ];       # which traits to activate
    schema.base.system = "x86_64-linux";
    schema.ssh.port = 2222;          # override schema defaults
    includes = [                     # extra modules
      { services.fail2ban.enable = true; }
      ./hardware-configuration.nix
    ];
  };
}
```

**traits** — List of trait names to activate. Referencing a non-existent name is an error.

**schema** — Type-checked values matching the global schema declarations. Unset values use the declared defaults. Schema values are exposed in the evaluation result alongside the module, so they can be used for routing (e.g. `node.schema.base.system`).

**includes** — Additional modules appended after trait modules.

### Includes

Paths or attrsets are passed directly as modules:

```nix
includes = [
  ./hardware-configuration.nix
  { services.fail2ban.enable = true; }
];
```

## Multi-platform

nixy doesn't prescribe how nodes are routed to builders. Use standard Nix:

```nix
let
  cluster = nixy.eval { inherit lib; imports = [ ./. ]; args = { inherit inputs; }; };
  bySchema = pred: lib.filterAttrs (_: n: pred n.schema) cluster.nodes;
in {
  nixosConfigurations = lib.mapAttrs (_: n:
    lib.nixosSystem { system = n.schema.base.system; modules = [ n.module ]; }
  ) (bySchema (s: s.base.target or "nixos" == "nixos"));

  darwinConfigurations = lib.mapAttrs (_: n:
    inputs.darwin.lib.darwinSystem { system = n.schema.base.system; modules = [ n.module ]; }
  ) (bySchema (s: s.base.target or null == "darwin"));
}
```

## Composition with extend

`extend` lets you layer additional imports onto an existing evaluation, which is useful when building reusable libraries:

```nix
# A library provides base traits and schema
base = nixy.eval { inherit lib; imports = [ ./base ]; };

# Consumers extend it with their own modules
mine = base.extend { imports = [ ./my-stuff ]; };
```

This re-evaluates with the combined imports. Schema, traits, and nodes from both sources are merged.

## Imports and Scanning

`nixy.eval` scans `imports` recursively:

- **Directories** are scanned for all `.nix` files (recursively)
- **Files** (`.nix`) are loaded directly
- **Attrsets** are passed through as inline modules
- **Lists** are flattened

By default, files starting with `_` or `.`, plus `flake.nix` and `default.nix`, are excluded. Override with `exclude`:

```nix
nixy.eval {
  inherit lib;
  imports = [ ./. ];
  exclude = { name, path }: name == "test.nix";
}
```

## Cross-node References

Traits can read other nodes' schema and trait list via the `nodes` argument:

```nix
traits.client = { schema, nodes, ... }: {
  services.myApp.serverHost = nodes.server.schema.net.ip;
};
```

## Error Tracking

nixy tags each trait and include module with location information. When an evaluation error occurs, the trace includes the source (trait name or include index) and node name.
