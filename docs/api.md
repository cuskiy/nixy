# API Reference

## nixy.eval

The main entry point. Takes `lib` and a configuration attrset, returns the evaluated result.

```nix
nixy.eval lib {
  imports ? [ ];
  args ? { };
  exclude ? null;
}
```

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `lib` | Nixpkgs `lib` (e.g. `nixpkgs.lib`) |
| `imports` | Directories, `.nix` files, attrsets, or lists thereof |
| `args` | Passed to framework modules (via `specialArgs`) and to trait/include modules (via the outer function) |
| `exclude` | `{ name, path } -> bool` — return `true` to skip a file during scanning |

**Returns:**

```nix
{
  nodes.<n> = {
    module = { ... };   # NixOS/Darwin/HM module — pass to nixosSystem etc.
    meta = { ... };     # Free-form user data from the node definition
  };
  _nixy = {
    schemaEntries = [ ... ];
    traitNames = [ ... ];
    nodeNames = [ ... ];
    nodes = { ... };
  };
}
```

## Top-level Options

These options are available in every loaded `.nix` file:

| Option | Type | Description |
|--------|------|-------------|
| `schema` | deep-merged attrset | Option declarations (the knobs) |
| `traits` | list of `{ name, module }` | Behavior units |
| `nodes` | attrsOf submodule | Machine definitions |

## Node Fields

Each node accepts:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `meta` | deep-merged attrset | `{ }` | Free-form user data |
| `traits` | list of strings | `[ ]` | Trait names to activate |
| `schema` | submodule | `{ }` | Values matching global schema |
| `includes` | list of raw | `[ ]` | Extra modules (paths, attrsets, or functions) |

## Trait Structure

Traits use the two-function form. The outer function takes framework args, the inner is a NixOS module:

```nix
{
  name = "ssh";
  module =
    { conf, config, pkgs, lib, ... }:           # NixOS and framework module args
    {
      # NixOS configuration
    };
}
```

## Scanning Defaults

Files excluded by default: names starting with `_` or `.`, `flake.nix`, `default.nix`. Symlinks are skipped with a trace warning.
