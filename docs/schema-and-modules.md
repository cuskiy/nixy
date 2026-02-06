# Schema & Modules

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

Options are declared with helpers like `mkStr` and `mkPort`, or with `lib.mkOption` directly. A few names are reserved and cannot appear in schema paths: `enable`, `load`, `system`, `target`, `extraModules`, and `instantiate`.

## modules.*.load

A list of NixOS/Darwin/HM modules that get loaded when the module is enabled on a host. These modules receive some extra arguments in addition to `args`:

| Argument | Description |
|----------|-------------|
| `host` | Current host's config |
| `hosts` | All hosts' configs |
| `name` | Host name |
| `system` | System string |
| `target` | Resolved target |

## enable

Every module gets an `enable` option automatically. If a module is not enabled, any options set on it are silently ignored.

```nix
hosts.server.ssh.enable = true;
hosts.server.ssh.port = 2222;
```
