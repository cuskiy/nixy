# Configuration

## nixy.eval

The main entry point. It takes your configuration and returns a flake outputs attrset.

```nix
nixy.eval {
  nixpkgs;
  imports ? [ ];
  args ? { };
  exclude ? null;
}
```

### imports

Directories are scanned recursively for `.nix` files. You can also pass individual files or inline attrsets.

```nix
imports = [
  ./.
  ./modules
  ./special.nix
  { hosts.extra = { ... }; }
];
```

### args

Everything in `args` is passed through to both framework modules and NixOS/Darwin/HM modules via `specialArgs`.

```nix
args = { inherit inputs; };
```

### exclude

Controls which files are skipped during directory scanning. By default, files starting with `_` or `.`, as well as `flake.nix` and `default.nix`, are excluded.

```nix
exclude = { name, path }:
  name == "test.nix" || lib.hasPrefix "_" name;
```

## Top-level Options

| Option | Description |
|--------|-------------|
| `systems` | Systems for `perSystem`, defaults to x86_64/aarch64 linux/darwin |
| `schema.*` | Option declarations |
| `modules.*` | Module load lists |
| `hosts.*` | Host definitions |
| `targets.*` | Target builders |
| `rules` | Build-time assertions |
| `perSystem` | Per-system outputs |
| `flake.*` | Extra flake outputs |
