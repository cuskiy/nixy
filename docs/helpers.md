# Option Helpers

Helpers simplify option declarations. All helpers are available as framework module arguments.

## Basic Types

### mkStr

String option. Pass `null` for optional (defaults to `null`), or a value for required with default.

```nix
{ mkStr, ... }:
{
  modules.web.options = {
    domain = mkStr null;           # optional, default null
    protocol = mkStr "https";      # required, default "https"
  };
}
```

### mkBool

Boolean option.

```nix
{ mkBool, ... }:
{
  modules.service.options = {
    enabled = mkBool true;
    debug = mkBool false;
  };
}
```

### mkInt

Integer option.

```nix
{ mkInt, ... }:
{
  modules.cache.options = {
    maxSize = mkInt 1024;
    ttl = mkInt null;    # optional
  };
}
```

### mkPort

Port number (1-65535).

```nix
{ mkPort, ... }:
{
  modules.server.options = {
    httpPort = mkPort 80;
    httpsPort = mkPort 443;
  };
}
```

### mkPath

Path option.

```nix
{ mkPath, ... }:
{
  modules.backup.options = {
    destination = mkPath /var/backup;
    source = mkPath null;
  };
}
```

### mkLines

Multi-line string, lines are concatenated.

```nix
{ mkLines, ... }:
{
  modules.nginx.options = {
    extraConfig = mkLines "";
  };
}

# Usage in node:
nodes.web.nginx.extraConfig = ''
  gzip on;
  gzip_types text/plain application/json;
'';
```

### mkAttrs

Attribute set (untyped).

```nix
{ mkAttrs, ... }:
{
  modules.app.options = {
    environment = mkAttrs { };
  };
}

# Usage:
nodes.server.app.environment = {
  NODE_ENV = "production";
  PORT = "3000";
};
```

## Collections

### mkList

List with element type and default value.

```nix
{ mkList, lib, ... }:
{
  modules.firewall.options = {
    allowedPorts = mkList lib.types.port [ 22 80 443 ];
    blockedIPs = mkList lib.types.str [ ];
  };
}
```

### mkListOf

List with element type, empty default.

```nix
{ mkListOf, lib, ... }:
{
  modules.users.options = {
    admins = mkListOf lib.types.str;      # default: [ ]
    keys = mkListOf lib.types.path;
  };
}
```

### mkAttrsOf

Attribute set with typed values, empty default.

```nix
{ mkAttrsOf, lib, ... }:
{
  modules.dns.options = {
    records = mkAttrsOf lib.types.str;    # default: { }
  };
}

# Usage:
nodes.ns.dns.records = {
  "example.com" = "192.168.1.1";
  "api.example.com" = "192.168.1.2";
};
```

### mkStrList

Shorthand for `mkListOf lib.types.str`.

```nix
{ mkStrList, ... }:
{
  modules.git.options = {
    allowedUsers = mkStrList;    # default: [ ]
  };
}
```

## Choice Types

### mkEnum

One of predefined values.

```nix
{ mkEnum, ... }:
{
  modules.log.options = {
    level = mkEnum [ "debug" "info" "warn" "error" ] "info";
  };
}
```

### mkEither

One of two types.

```nix
{ mkEither, lib, ... }:
{
  modules.proxy.options = {
    upstream = mkEither lib.types.str lib.types.port "localhost";
  };
}

# Usage:
nodes.proxy.proxy.upstream = 8080;        # port
nodes.proxy.proxy.upstream = "backend";   # string
```

### mkOneOf

One of multiple types.

```nix
{ mkOneOf, lib, ... }:
{
  modules.config.options = {
    value = mkOneOf [ lib.types.str lib.types.int lib.types.bool ] "";
  };
}
```

## Advanced Types

### mkPackage

Package option, no default (must be set).

```nix
{ mkPackage, ... }:
{
  modules.editor.options = {
    package = mkPackage;
  };
}

# Usage:
nodes.dev.editor.package = pkgs.neovim;
```

### mkPackageOr

Package option with default.

```nix
{ mkPackageOr, pkgsFor, ... }:
let pkgs = pkgsFor "x86_64-linux";
in {
  modules.shell.options = {
    package = mkPackageOr pkgs.bash;
  };
}
```

### mkRaw

Raw type (any value), no default.

```nix
{ mkRaw, ... }:
{
  modules.custom.options = {
    builder = mkRaw;
  };
}
```

### mkRawOr

Raw type with default.

```nix
{ mkRawOr, ... }:
{
  modules.hook.options = {
    preStart = mkRawOr null;
  };
}
```

### mkNullable

Any type, nullable with `null` default.

```nix
{ mkNullable, lib, ... }:
{
  modules.db.options = {
    port = mkNullable lib.types.port;     # null or port
    host = mkNullable lib.types.str;
  };
}
```

## Submodules

### mkSub

Nested options as submodule.

```nix
{ mkSub, mkStr, mkPort, ... }:
{
  modules.database.options = {
    connection = mkSub {
      host = mkStr "localhost";
      port = mkPort 5432;
      name = mkStr null;
    };
  };
}

# Usage:
nodes.app.database.connection = {
  host = "db.example.com";
  port = 5432;
  name = "myapp";
};
```

### mkSubList

List of submodules.

```nix
{ mkSubList, mkStr, mkPort, mkInt, ... }:
{
  modules.lb.options = {
    backends = mkSubList {
      host = mkStr null;
      port = mkPort 80;
      weight = mkInt 1;
    };
  };
}

# Usage:
nodes.lb.lb.backends = [
  { host = "10.0.0.1"; port = 8080; }
  { host = "10.0.0.2"; port = 8080; weight = 2; }
];
```

## Enable Option

### mkEnable

Shorthand for `lib.mkEnableOption`. Used inside modules for sub-features.

```nix
{ mkEnable, ... }:
{
  modules.monitoring.options = {
    metrics = mkEnable "Prometheus metrics";
    logging = mkEnable "structured logging";
  };
}
```

Note: Don't use `mkEnable` for the module's main `enable` option - nixy adds that automatically.
