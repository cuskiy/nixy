# Configuration

## nixy.eval

```nix
nixy.eval {
  nixpkgs;          # required
  imports ? [ ];    # directories, files, or inline modules
  args ? { };       # passed to all modules
  exclude ? null;   # filter function
}
```

Returns a flake outputs attrset.

### imports

Accepts paths, directories, or inline attrsets:

```nix
imports = [
  ./.           # scan current directory recursively
  ./modules     # scan specific directory
  ./special.nix # single file
  { ... }       # inline module
];
```

### args

Extra arguments passed to framework modules and NixOS/Darwin/HM modules via `specialArgs`:

```nix
args = { inherit inputs; myArg = "value"; };
```

### exclude

Filter scanned files. Default excludes `_*`, `.*`, `flake.nix`, `default.nix`:

```nix
exclude = { name, path }:
  name == "test.nix" || lib.hasPrefix "_" name;
```

## Top-level Options

| Option | Description |
|--------|-------------|
| `systems` | Systems for `perSystem` (default: x86_64/aarch64 linux/darwin) |
| `schema.*` | Option declarations (deep-merged across files) |
| `modules.*` | Module load lists (merged across files) |
| `hosts.*` | Host definitions |
| `targets.*` | Target builders |
| `rules` | Build-time assertions |
| `perSystem` | Per-system outputs (deep-merged across files) |
| `flake.*` | Extra flake outputs |
