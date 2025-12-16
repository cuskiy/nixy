# Option Helpers

Nixy provides helper functions for common option patterns. All helpers are available as framework module arguments.

## Basic Types

| Helper | Equivalent | Description |
|--------|------------|-------------|
| `mkStr default` | `mkOption { type = str; }` | String option |
| `mkBool default` | `mkOption { type = bool; }` | Boolean option |
| `mkInt default` | `mkOption { type = int; }` | Integer option |
| `mkPort default` | `mkOption { type = port; }` | Port (1-65535) |
| `mkPath default` | `mkOption { type = path; }` | Path option |
| `mkLines default` | `mkOption { type = lines; }` | Multi-line string |
| `mkAttrs default` | `mkOption { type = attrs; }` | Attribute set |

When `default` is `null`, the option becomes `nullOr type` with `null` default.

## Collections

| Helper | Description |
|--------|-------------|
| `mkList type default` | List with element type |
| `mkListOf type` | List with empty default |
| `mkAttrsOf type` | Attrs with empty default |
| `mkStrList` | `listOf str` with `[]` default |

## Complex Types

| Helper | Description |
|--------|-------------|
| `mkEnum values default` | Enum from list |
| `mkEither t1 t2 default` | Either of two types |
| `mkOneOf types default` | One of multiple types |
| `mkNullable type` | Nullable with null default |

## Advanced

| Helper | Description |
|--------|-------------|
| `mkPackage` | Package (no default) |
| `mkPackageOr default` | Package with default |
| `mkRaw` | Raw type (no default) |
| `mkRawOr default` | Raw with default |
| `mkSub opts` | Submodule with options |
| `mkSubList opts` | List of submodules |
| `mkEnable name` | `lib.mkEnableOption` |

## Examples

```nix
{ mkStr, mkBool, mkList, mkSub, lib, ... }:
{
  modules.example.options = {
    name = mkStr null;
    enabled = mkBool true;
    ports = mkList lib.types.port [ 80 443 ];
    
    database = mkSub {
      host = mkStr "localhost";
      port = mkPort 5432;
    };
  };
}
```
