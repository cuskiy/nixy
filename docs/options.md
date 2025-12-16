# Framework Options

## systems

```nix
systems = [ "x86_64-linux" "aarch64-darwin" ];
```

List of systems for `perSystem` outputs. Default includes all common platforms.

## modules.\<name\>

```nix
modules.myModule = {
  target = null;      # "nixos" | "darwin" | "home" | null
  requires = [ ];     # list of module names
  options = { };      # option declarations
  module = { };       # NixOS/Darwin/HM module
};
```

## nodes.\<name\>

```nix
nodes.myNode = {
  system = "x86_64-linux";  # required
  target = null;            # override inferred target
  extraModules = [ ];       # additional modules
  instantiate = null;       # custom builder
  
  # module options
  myModule.enable = true;
  myModule.setting = "value";
};
```

## targets.\<name\>

```nix
targets.darwin = {
  instantiate = { system, modules, specialArgs }: ...;
  output = "darwinConfigurations";
};
```

Built-in: `nixos`

## rules

```nix
rules = [
  { assertion = bool; message = "error text"; }
];
```

## perSystem

```nix
perSystem = { pkgs, system }: {
  packages = { };
  devShells = { };
  checks = { };
  formatter = pkgs.nixfmt-rfc-style;
  apps = { };
};
```

## flake

```nix
flake = {
  overlays.default = ...;
  lib = { };
  # any valid flake output
};
```
