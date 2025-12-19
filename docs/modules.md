# Modules

## Definition

```nix
{ mkStr, mkBool, ... }:
{
  modules.myModule = {
    target = "nixos";           # "nixos", "darwin", "home", or null (all)
    requires = [ "base" ];      # dependencies
    options = {
      setting = mkStr "default";
    };
    module = { node, ... }: {
      # NixOS/Darwin/HM config
    };
  };
}
```

## Fields

### target

Restricts module to specific platforms:
- `"nixos"` - NixOS only
- `"darwin"` - nix-darwin only
- `"home"` - Home Manager only
- `null` - All platforms

### requires

List of module names that must be enabled:

```nix
modules.desktop = {
  requires = [ "base" "gui" ];
  # ...
};
```

Build fails if requirements aren't met.

### options

Option declarations using helpers or standard `lib.mkOption`:

```nix
options = {
  name = mkStr null;
  enabled = mkBool true;
  ports = mkList lib.types.port [ 80 443 ];
};
```

### module

NixOS/Darwin/HM module. Receives special arguments:

| Argument | Description |
|----------|-------------|
| `node` | Current node's clean config |
| `nodes` | All nodes' clean configs |
| `name` | Node name |
| `system` | System string |

## Splitting Modules

Same-name modules across files are merged:

```nix
# modules/base/base.nix
modules.base.options.hostName = mkStr null;
modules.base.module = { node, ... }: {
  networking.hostName = node.base.hostName;
};

# modules/base/boot.nix
modules.base.module = {
  boot.loader.systemd-boot.enable = true;
};
```
