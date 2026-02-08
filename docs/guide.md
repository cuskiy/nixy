# Guide

Nixy organizes configuration around three concepts: **schema** declares options, **traits** implement behavior, and **nodes** define machines.

## Schema

Declare options with helpers like `mkStr` and `mkPort`. Multiple files can contribute to the same schema tree — they are deep-merged.

```nix
{ mkStr, mkPort, mkBool, ... }:
{
  schema.ssh = {
    port = mkPort 22;
    permitRoot = mkBool false;
  };

  schema.base.hostName = mkStr null;
}
```

All helpers wrap their type in `nullOr`, so every option accepts `null`. See [Helpers](/helpers) for the full list.

## Traits

A trait is a named behavior unit. The module uses the **two-function form**: the outer function receives framework arguments, the inner function is a standard NixOS/Darwin/HM module.

```nix
traits = [{
  name = "ssh";
  module = { conf, ... }: { config, pkgs, ... }: {
    services.openssh = {
      enable = true;
      ports = [ conf.ssh.port ];
      settings.PermitRootLogin =
        if conf.ssh.permitRoot then "yes" else "no";
    };
  };
}];
```

The two functions keep framework concerns and NixOS concerns separate. The outer function runs at framework time; the inner function runs during NixOS evaluation.

### Framework arguments

The outer function receives:

| Argument | Description |
|----------|-------------|
| `conf` | Current node's resolved schema values |
| `name` | Current node name |
| `nodes` | All nodes (`{ meta, schema, traits }` each) |
| _..._ | Everything from `args` (e.g. `inputs`) |

The inner function receives standard NixOS/Darwin/HM arguments (`config`, `pkgs`, `lib`, etc).

### Trait names

Names must be unique across the entire configuration. Duplicate names abort evaluation with an error. Multiple files can each contribute their own `traits` list — the lists are concatenated.

## Nodes

Each node represents a machine. It has four fields:

```nix
{
  nodes.server = {
    meta.system = "x86_64-linux";    # free-form user data
    meta.deploy.host = "10.0.0.1";   # arbitrary nesting
    traits = [ "base" "ssh" ];       # which traits to activate
    schema.ssh.port = 2222;          # override schema defaults
    includes = [                     # extra modules
      { services.fail2ban.enable = true; }
      ./hardware-configuration.nix
    ];
  };
}
```

**meta** — Free-form attrset for user data. Nixy passes it through without interpretation. Common uses: `system`, deployment targets, tags.

**traits** — List of trait names to activate. Referencing a non-existent name is an error.

**schema** — Type-checked values matching the global schema declarations. Unset values use the declared defaults.

**includes** — Additional modules appended after trait modules. See below.

### Includes

Includes support three forms:

**Plain NixOS modules** — paths, attrsets, or functions with NixOS args are passed through unchanged:

```nix
includes = [
  ./hardware-configuration.nix
  { services.fail2ban.enable = true; }
];
```

**Two-function form** — if an include needs framework args (`conf`, `nodes`, etc.), use the same two-function pattern as traits:

```nix
includes = [
  ./resource.nix   # contains: { conf, ... }: { pkgs, ... }: { ... }
];
```

Nixy auto-detects the form: if the function's formal parameters include NixOS-specific names (`config`, `pkgs`, `options`, `lib`, `modulesPath`), it's treated as a plain NixOS module. Otherwise, it's treated as a two-function form and called with framework args.

## Rules

Build-time assertions that are checked before nodes are returned.

```nix
{ config, ... }:
{
  rules = [
    {
      assertion = config.nodes ? server;
      message = "a 'server' node is required";
    }
  ];
}
```

## Multi-platform

Nixy doesn't prescribe how nodes are routed to builders. Use standard Nix:

```nix
let
  cluster = nixy.eval lib { imports = [ ./. ]; args = { inherit inputs; }; };
  byMeta = pred: lib.filterAttrs (_: n: pred n.meta) cluster.nodes;
in {
  nixosConfigurations = lib.mapAttrs (_: n:
    lib.nixosSystem { system = n.meta.system; modules = [ n.module ]; }
  ) (byMeta (m: m.target or "nixos" == "nixos"));

  darwinConfigurations = lib.mapAttrs (_: n:
    inputs.darwin.lib.darwinSystem { system = n.meta.system; modules = [ n.module ]; }
  ) (byMeta (m: m.target or null == "darwin"));
}
```

## Imports and Scanning

`nixy.eval` scans `imports` recursively:

- **Directories** are scanned for all `.nix` files (recursively)
- **Files** (`.nix`) are loaded directly
- **Attrsets** are passed through as inline modules
- **Lists** are flattened

By default, files starting with `_` or `.`, plus `flake.nix` and `default.nix`, are excluded. Override with `exclude`:

```nix
nixy.eval lib {
  imports = [ ./. ];
  exclude = { name, path }: name == "test.nix";
}
```

All loaded files receive `specialArgs`: `lib`, all helpers (`mkStr`, `mkBool`, ...), and everything in `args`.

## Cross-node References

Traits can read other nodes' data via the `nodes` argument:

```nix
traits = [{
  name = "client";
  module = { conf, nodes, ... }: { ... }: {
    services.myApp.serverHost = nodes.server.schema.net.ip;
  };
}];
```

## Error Tracking

Nixy tags each trait and include module with location information. When an evaluation error occurs, the trace includes the source (trait name or include index) and node name.
