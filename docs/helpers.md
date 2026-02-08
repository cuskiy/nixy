# Helpers

All helpers are available in the module argument set (e.g. `{ mkStr, mkPort, ... }:`). They are convenience wrappers that create `lib.mkOption` with `nullOr` types.

## Schema Helpers

| Helper | Type | Example |
|--------|------|---------|
| `mkStr default` | `nullOr str` | `mkStr "hello"` |
| `mkBool default` | `nullOr bool` | `mkBool false` |
| `mkInt default` | `nullOr int` | `mkInt 0` |
| `mkPort default` | `nullOr port` | `mkPort 22` |
| `mkPath default` | `nullOr path` | `mkPath null` |
| `mkLines default` | `nullOr lines` | `mkLines ""` |
| `mkPackage default` | `nullOr package` | `mkPackage null` |
| `mkRaw default` | `nullOr raw` | `mkRaw null` |
| `mkEnum values default` | `nullOr (enum values)` | `mkEnum [ "a" "b" ] "a"` |
| `mkList elemType default` | `nullOr (listOf elemType)` | `mkList lib.types.str null` |
| `mkAttrsOf valType default` | `nullOr (attrsOf valType)` | `mkAttrsOf lib.types.str null` |
| `mkEither a b default` | `nullOr (either a b)` | `mkEither lib.types.str lib.types.int null` |
| `mkSub options` | `submodule` | `mkSub { name = mkStr null; }` |
| `mkSubList options` | `listOf submodule` | `mkSubList { host = mkStr null; }` |

Every `nullOr` helper accepts `null` as a valid value, which makes all schema options optional by default.
