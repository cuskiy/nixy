# API Reference

## nixy.eval

The main entry point. Takes a configuration attrset, returns the evaluated result.

```nix
nixy.eval {
  inherit (nixpkgs) lib;
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
| `args` | Extra arguments available in all modules (see below) |
| `exclude` | `{ name, path } -> bool` — return `true` to skip a file during scanning |

**Returns:**

```nix
{
  nodes.<n> = {
    module = { ... };   # Module bundle — pass to nixosSystem, darwinSystem, etc.
    schema = { ... };   # Evaluated schema values for this node
  };
  extend = { ... };     # Layer additional imports (see below)
}
```

Users can contribute additional data to the result via `_result` in their configuration files.

## extend

Layer additional imports and args onto an existing evaluation:

```nix
cluster.extend {
  imports ? [ ];   # Additional imports to merge
  args ? { };      # Additional args (merged with //)
  exclude ? null;  # Override the exclude function
}
```

Returns a new result with the same shape. The original evaluation is not modified.

## args

Values passed via `args` are available in both nixy-level files (schema/traits/nodes definitions) and inside trait and include modules.

## Top-level Options

These options are available in every loaded `.nix` file:

| Option | Type | Description |
|--------|------|-------------|
| `schema` | deep-merged attrset | Option declarations (the knobs) |
| `traits` | attrsOf raw | Behavior units (name = key, value = module) |
| `nodes` | lazyAttrsOf submodule | Target definitions |

Nodes use a lazy attribute set type, so accessing one node does not force evaluation of others.

## Node Fields

Each node accepts:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `traits` | list of strings | `[ ]` | Trait names to activate |
| `schema` | submodule | `{ }` | Values matching global schema |
| `includes` | list of raw | `[ ]` | Extra modules (paths, attrsets, or functions) |

## Trait Structure

A trait's key is its name, and the value is a module (path, function, or attribute set). Duplicate names across files are caught by the module system.

```nix
traits.ssh =
  { schema, config, pkgs, lib, ... }:
  {
    # Configuration
  };
```

## Module Arguments

Inside trait and include modules, these framework arguments are available alongside standard module args (`config`, `pkgs`, `lib`, ...):

| Argument | Description |
|----------|-------------|
| `name` | The node's attribute name |
| `schema` | Evaluated schema values for this node |
| `nodes` | All nodes' `{ schema, traits }` for cross-references |

Plus everything passed via `args` to `nixy.eval`.

## Scanning Defaults

Files excluded by default: names starting with `_` or `.`, `flake.nix`, `default.nix`.
