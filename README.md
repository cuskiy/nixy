# Nixy

**nixy** is a module builder that helps structure large Nix configurations without altering the native module system.

It models configuration around three concepts:

* **Schema**
  Declares typed options with sensible defaults.
  Definitions from multiple files are deep-merged into a single tree.

* **Traits**
  Named behavior units that transform schema values into concrete configuration.

* **Nodes**
  Each node selects its traits, overrides schema values, and produces a ready-to-use module.

The result is standard Nix modules, fully compatible with `lib.evalModules` and `lib.nixosSystem`.

## How it works

* Collects modules from files, directories, or inline definitions
* Merges all schema declarations into a single typed option tree
* Composes node-specific modules by selecting traits and wiring values
* Ensures only referenced traits participate in the final configuration

Nixy only controls **which modules participate** and **which values are wired in**.

## Example

Define schema and traits:

```nix
{ mkPort, ... }:
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

Wire into a flake:

```nix
{
  outputs = { nixpkgs, nixy, ... }@inputs:
    let
      lib = nixpkgs.lib;
      cluster = nixy.eval {
        inherit lib;
        imports = [ ./. ];
        args = { inherit inputs; };
      };
    in {
      nixosConfigurations =
        lib.mapAttrs (_: node:
          lib.nixosSystem {
            system = node.schema.base.system;
            modules = [ node.module ];
          }
        ) cluster.nodes;
    };
}
```

## Try it

```bash
nix flake init -t github:cuskiy/nixy#minimal
```

---

## License

Apache-2.0
