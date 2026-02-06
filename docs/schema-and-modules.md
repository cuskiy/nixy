# Schema & Modules

## Overview

Nixy separates option declarations (`schema`) from implementation (`modules.*.load`). They can live in the same file or be split across files — definitions are merged.

```nix
{ mkStr, mkBool, mkPort, ... }:
{
  schema.ssh = {
    port = mkPort 22;
    permitRoot = mkBool false;
  };

  modules.ssh.load = [({ host, ... }: {
    services.openssh = {
      enable = true;
      ports = [ host.ssh.port ];
      settings.PermitRootLogin = if host.ssh.permitRoot then "yes" else "no";
    };
  })];
}
```

## schema

Option declarations using helpers or `lib.mkOption`. Paths are validated — `enable`, `load`, `system`, `target`, `extraModules`, and `instantiate` are reserved.

Options are deep-merged across files, so multiple files can contribute to the same schema namespace:

```nix
# file A
schema.net.ip = mkStr null;

# file B
schema.net.dns = mkStr "1.1.1.1";
```

## modules.*.load

A list of NixOS/Darwin/HM modules to load when the module is enabled on a host. Receives special arguments:

| Argument | Description |
|----------|-------------|
| `host` | Current host's config (with `target` resolved) |
| `hosts` | All hosts' configs |
| `name` | Host name |
| `system` | System string |
| `target` | Resolved target string |

Plus anything passed via `args`.

## Enable

Nixy automatically adds an `enable` option to each module. A host enables a module with:

```nix
hosts.server.ssh.enable = true;
```

Setting options on a disabled module is allowed (they are simply ignored).

## Schema-only Modules

A module can define only schema (no load) for pure data:

```nix
schema.meta.role = mkStr null;
modules.meta.load = [ ];
```

## Splitting Across Files

Same-name modules across files are merged:

```nix
# modules/ssh/config.nix
schema.ssh.port = mkPort 22;
modules.ssh.load = [({ host, ... }: {
  services.openssh.ports = [ host.ssh.port ];
})];

# modules/ssh/firewall.nix
modules.ssh.load = [({ host, ... }: {
  networking.firewall.allowedTCPPorts = [ host.ssh.port ];
})];
```
