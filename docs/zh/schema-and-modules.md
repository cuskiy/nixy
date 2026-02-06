# Schema 与 Modules

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

用 `mkStr`、`mkPort` 等 helpers 或直接用 `lib.mkOption` 声明选项。以下名称为保留字，不能出现在 schema 路径中：`enable`、`load`、`system`、`target`、`extraModules`、`instantiate`。

## modules.*.load

当模块在某个 host 上被启用时，这里列出的 NixOS/Darwin/HM 模块会被加载。除了 `args` 中的内容，还有一些额外的参数可用：

| 参数 | 说明 |
|------|------|
| `host` | 当前主机配置 |
| `hosts` | 所有主机配置 |
| `name` | 主机名 |
| `system` | 系统字符串 |
| `target` | 解析后的 target |

## enable

每个模块会自动获得一个 `enable` 选项。如果模块未启用，设置在上面的选项会被忽略。

```nix
hosts.server.ssh.enable = true;
hosts.server.ssh.port = 2222;
```
