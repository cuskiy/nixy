# Nodes

## Definition

```nix
{
  nodes.myMachine = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "my-machine";
  };
}
```

## Fields

### system (required)

Target system: `"x86_64-linux"`, `"aarch64-linux"`, `"aarch64-darwin"`, `"x86_64-darwin"`

### target

Override inferred target. Usually automatic:
- `*-darwin` → `"darwin"`
- `*-linux` → `"nixos"`

Set explicitly for Home Manager:

```nix
nodes."user@host" = {
  system = "x86_64-linux";
  target = "home";
  # ...
};
```

### extraModules

Additional NixOS/Darwin/HM modules:

```nix
nodes.server = {
  # ...
  extraModules = [
    { services.openssh.enable = true; }
    ./hardware-configuration.nix
  ];
};
```

### instantiate

Custom builder function:

```nix
nodes.stable-server = {
  system = "x86_64-linux";
  instantiate = { system, modules, specialArgs }:
    inputs.nixpkgs-stable.lib.nixosSystem {
      inherit system modules specialArgs;
    };
  # ...
};
```

## Module Options

Enable modules and set options:

```nix
nodes.desktop = {
  system = "x86_64-linux";
  
  base.enable = true;
  base.hostName = "desktop";
  base.timeZone = "America/New_York";
  
  gui.enable = true;
  gui.driver = "nvidia";
};
```

Setting options without `enable = true` throws an error.
