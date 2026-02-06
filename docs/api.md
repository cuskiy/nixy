# API Reference

## nixy.eval

The main entry point. Returns a flake outputs attrset.

```nix
nixy.eval {
  nixpkgs;
  imports ? [ ];
  args ? { };
  exclude ? null;
}
```

## targets

Define how hosts of a given target are built. The `nixos` target is built-in; everything else needs to be registered here.

```nix
targets.darwin = {
  instantiate = { system, modules, specialArgs }: ...;
  output = "darwinConfigurations";
};
```

## rules

Assertions that are checked at build time. If any assertion fails, the build is aborted with the corresponding message.

```nix
rules = [
  { assertion = config.hosts ? server; message = "server host required"; }
];
```

## perSystem

Per-system outputs like packages, dev shells, and formatters.

```nix
perSystem = { pkgs, system }: {
  packages.hello = pkgs.hello;
  devShells.default = pkgs.mkShell { };
  formatter = pkgs.nixfmt-rfc-style;
};
```

## flake

Arbitrary extra flake outputs.

```nix
flake.overlays.default = final: prev: { };
flake.deploy.nodes = { ... };
```

## Generated Outputs

Nixy produces the following flake outputs:

- `nixosConfigurations.<name>` and any custom target outputs
- `formatter.<system>`
- `apps.<system>.check`
- `packages`, `devShells`, `checks`, `legacyPackages` from `perSystem`
