# Helpers

Helpers 是 `lib.mkOption` 的简写。每个 helper 都会将类型包装在 `nullOr` 中，因此所有选项都接受 `null`。

## 基本类型

| Helper | 类型 | 示例 |
|--------|------|------|
| `mkStr` | `str` | `mkStr "default"` / `mkStr null` |
| `mkBool` | `bool` | `mkBool true` |
| `mkInt` | `int` | `mkInt 1024` |
| `mkPort` | `port` | `mkPort 443` |
| `mkPath` | `path` | `mkPath /var/data` |
| `mkLines` | `lines` | `mkLines ""` |
| `mkPackage` | `package` | `mkPackage null` |
| `mkRaw` | `raw` | `mkRaw null` |

## 选择类型

| Helper | 签名 | 示例 |
|--------|------|------|
| `mkEnum` | `[values] -> default -> option` | `mkEnum ["debug" "info" "error"] "info"` |
| `mkEither` | `type -> type -> default -> option` | `mkEither lib.types.str lib.types.port "localhost"` |

## 集合类型

| Helper | 签名 | 示例 |
|--------|------|------|
| `mkList` | `elemType -> default -> option` | `mkList lib.types.port [80 443]` |
| `mkAttrsOf` | `valType -> default -> option` | `mkAttrsOf lib.types.str null` |

## 子模块

`mkSub` 创建嵌套选项组，默认值为 `{ }`：

```nix
schema.db.connection = mkSub {
  host = mkStr "localhost";
  port = mkPort 5432;
};
```

`mkSubList` 创建子模块列表，默认值为 `[ ]`：

```nix
schema.lb.backends = mkSubList {
  host = mkStr null;
  port = mkPort 80;
  weight = mkInt 1;
};
```
