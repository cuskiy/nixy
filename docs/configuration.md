# Configuration

## mkFlake / mkConfiguration

```nix
nixy.mkFlake {
  nixpkgs;          # required - nixpkgs input
  imports ? [ ];    # directories or files to scan
  args ? { };       # passed to all modules
  exclude ? null;   # filter function
}
```

### imports

Accepts paths, directories, or inline modules:

```nix
imports = [
  ./.           # scan current directory
  ./modules     # scan specific directory
  ./special.nix # single file
  { ... }       # inline module
];
```

### args

Passed to framework modules and NixOS/Darwin/HM modules:

```nix
args = { inherit inputs; myCustomArg = "value"; };
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
| `systems` | Target systems (default: x86_64/aarch64 linux/darwin) |
| `modules.*` | Module definitions |
| `nodes.*` | Node definitions |
| `targets.*` | Target builders |
| `rules` | Build-time assertions |
| `perSystem` | Per-system outputs |
| `flake.*` | Extra flake outputs |
