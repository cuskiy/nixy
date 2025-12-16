# API Reference

## Entry Points

### mkFlake

Main entry point for flake-based configurations.

```nix
nixy.mkFlake {
  nixpkgs;
  imports ? [ ];
  args ? { };
  exclude ? null;
}
```

Returns a flake outputs attrset.

### mkConfiguration

Alias for `mkFlake`. Use for non-flake setups:

```nix
nixy.mkConfiguration {
  nixpkgs;
  imports = [ ./. ];
}
```

## Framework Module Arguments

Available in framework modules (files defining `modules.*`):

| Argument | Type | Description |
|----------|------|-------------|
| `lib` | attrset | nixpkgs.lib |
| `nixpkgs` | attrset | nixpkgs input |
| `config` | attrset | Framework configuration |
| `pkgsFor` | function | `system -> pkgs` |
| `mkStr`, etc. | function | Option helpers |

## NixOS/Darwin/HM Module Arguments

Available in `modules.*.module`:

| Argument | Type | Description |
|----------|------|-------------|
| `node` | attrset | Current node config |
| `nodes` | attrset | All node configs |
| `name` | string | Node name |
| `system` | string | System string |

Plus anything passed via `args`.

## Flake Outputs

Nixy generates:

- `nixosConfigurations.<name>`
- `darwinConfigurations.<name>`
- `homeConfigurations.<name>`
- `formatter.<system>`
- `apps.<system>.{allOptions,allNodes,checkOptions}`
- Custom outputs via `perSystem` and `flake.*`

## targets

Define custom targets:

```nix
targets.darwin = {
  instantiate = { system, modules, specialArgs }:
    nix-darwin.lib.darwinSystem { inherit system modules specialArgs; };
  output = "darwinConfigurations";
};
```

## rules

Build-time assertions:

```nix
rules = [
  {
    assertion = config.nodes ? server;
    message = "server node must be defined";
  }
];
```

## perSystem

Per-system outputs:

```nix
perSystem = { pkgs, system }: {
  packages.hello = pkgs.hello;
  devShells.default = pkgs.mkShell { };
  formatter = pkgs.nixfmt-rfc-style;
};
```

## flake

Extra flake outputs:

```nix
flake.overlays.default = final: prev: { };
flake.lib.myHelper = x: x;
```
