# API Reference

## Entry Point

### nixy.eval

```nix
nixy.eval {
  nixpkgs;
  imports ? [ ];
  args ? { };
  exclude ? null;
}
```

Returns a flake outputs attrset.

## Framework Options

### schema

Deep-merged option declarations:

```nix
schema.myModule.setting = mkStr "default";
```

### modules

Module tree with `load` leaves:

```nix
modules.myModule.load = [({ host, ... }: { ... })];
```

### hosts

Host definitions:

```nix
hosts.myHost = {
  system = "x86_64-linux";
  myModule.enable = true;
  myModule.setting = "value";
};
```

### targets

Custom target builders:

```nix
targets.darwin = {
  instantiate = { system, modules, specialArgs }: ...;
  output = "darwinConfigurations";
};
```

Built-in: `nixos`.

### rules

Build-time assertions:

```nix
rules = [
  { assertion = config.hosts ? server; message = "server host required"; }
];
```

### perSystem

Per-system outputs. Multiple definitions are deep-merged:

```nix
perSystem = { pkgs, system }: {
  packages.hello = pkgs.hello;
  devShells.default = pkgs.mkShell { };
  formatter = pkgs.nixfmt-rfc-style;
};
```

### flake

Extra flake outputs:

```nix
flake.overlays.default = final: prev: { };
flake.deploy.nodes = { ... };
```

## Generated Outputs

- `nixosConfigurations.<n>` (and custom target outputs)
- `formatter.<s>`
- `apps.<s>.check`
- `packages.<s>.*`, `devShells.<s>.*`, etc. (from `perSystem`)
