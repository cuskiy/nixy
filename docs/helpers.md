# Helpers

All helpers are available as framework module arguments. Every helper wraps the type in `nullOr`, so all options accept `null`.

## Basic Types

| Helper | Type | Example |
|--------|------|---------|
| `mkStr` | `str` | `mkStr "default"` or `mkStr null` |
| `mkBool` | `bool` | `mkBool true` |
| `mkInt` | `int` | `mkInt 1024` |
| `mkPort` | `port` | `mkPort 443` |
| `mkPath` | `path` | `mkPath /var/data` |
| `mkLines` | `lines` | `mkLines ""` |
| `mkPackage` | `package` | `mkPackage null` |
| `mkRaw` | `raw` | `mkRaw null` |

```nix
{ mkStr, mkPort, ... }:
{
  schema.web = {
    domain = mkStr null;
    port = mkPort 443;
  };
}
```

## Choice Types

| Helper | Signature | Example |
|--------|-----------|---------|
| `mkEnum` | `[values] -> default -> option` | `mkEnum ["debug" "info" "error"] "info"` |
| `mkEither` | `type -> type -> default -> option` | `mkEither lib.types.str lib.types.port "localhost"` |

## Collections

| Helper | Signature | Example |
|--------|-----------|---------|
| `mkList` | `elemType -> default -> option` | `mkList lib.types.port [80 443]` |
| `mkAttrsOf` | `valType -> default -> option` | `mkAttrsOf lib.types.str null` |

## Submodules

### mkSub

Nested options. Default: `{ }`.

```nix
{ mkSub, mkStr, mkPort, ... }:
{
  schema.db.connection = mkSub {
    host = mkStr "localhost";
    port = mkPort 5432;
  };
}
```

### mkSubList

List of submodules. Default: `[ ]`.

```nix
{ mkSubList, mkStr, mkPort, mkInt, ... }:
{
  schema.lb.backends = mkSubList {
    host = mkStr null;
    port = mkPort 80;
    weight = mkInt 1;
  };
}
```

## Framework Arguments

Available in framework module files (files defining `schema.*` or `modules.*`):

| Argument | Description |
|----------|-------------|
| `lib` | nixpkgs.lib |
| `nixpkgs` | nixpkgs input |
| `config` | Framework configuration |
| `pkgsFor` | `system -> pkgs` |
| All helpers | `mkStr`, `mkBool`, etc. |
