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
| `args` | Passed to framework modules (via `specialArgs`) and to trait modules (via closure or outer function call) |
| `exclude` | `{ name, path } -> bool` — return `true` to skip a file during scanning |

**Returns:**

```nix
{
  nodes.<name> = {
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
| `rules` | list of `{ assertion, message }` | Build-time assertions |

## Node Fields

Each node accepts:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `meta` | deep-merged attrset | `{ }` | Free-form user data |
| `traits` | list of strings | `[ ]` | Trait names to activate |
| `schema` | submodule | `{ }` | Values matching global schema |
| `includes` | list of deferred modules | `[ ]` | Extra NixOS/Darwin/HM modules |

## Trait Structure

Two forms are supported. Nixy auto-detects which one you're using.

**Two-function form** (recommended — separates framework and NixOS concerns):

```nix
{
  name = "ssh";
  module = { conf, name, nodes, ... }:    # framework args
    { config, pkgs, lib, ... }:           # NixOS module args
    {
      # NixOS configuration
    };
}
```

**Flat form** (convenient — single function with all args):

```nix
{
  name = "ssh";
  module = { conf, config, pkgs, ... }: {
    # NixOS configuration
  };
}
```

Nixy detects flat modules by checking `builtins.functionArgs` for NixOS-specific names (`config`, `pkgs`, `options`, `modulesPath`). If found, it wraps the function automatically.

## Rules

Assertions checked at build time. If any fails, evaluation aborts.

```nix
rules = [
  { assertion = config.nodes ? server; message = "server node required"; }
];
```

## Scanning Defaults

Files excluded by default: names starting with `_` or `.`, `flake.nix`, `default.nix`. Symlinks are skipped with a trace warning.
