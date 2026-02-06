# 配置

## nixy.eval

主入口。接收配置后返回 flake outputs 属性集。

```nix
nixy.eval {
  nixpkgs;
  imports ? [ ];
  args ? { };
  exclude ? null;
}
```

### imports

目录会被递归扫描所有 `.nix` 文件，也可以直接传文件路径或内联属性集。

```nix
imports = [
  ./.
  ./modules
  ./special.nix
  { hosts.extra = { ... }; }
];
```

### args

`args` 中的内容会通过 `specialArgs` 传递给框架模块和 NixOS/Darwin/HM 模块。

```nix
args = { inherit inputs; };
```

### exclude

控制目录扫描时跳过哪些文件。默认排除 `_` 和 `.` 开头的文件，以及 `flake.nix` 和 `default.nix`。

```nix
exclude = { name, path }:
  name == "test.nix" || lib.hasPrefix "_" name;
```

## 顶层选项

| 选项 | 说明 |
|------|------|
| `systems` | `perSystem` 的目标系统，默认 x86_64/aarch64 linux/darwin |
| `schema.*` | 选项声明 |
| `modules.*` | 模块加载列表 |
| `hosts.*` | 主机定义 |
| `targets.*` | 目标构建器 |
| `rules` | 构建时断言 |
| `perSystem` | 按系统的输出 |
| `flake.*` | 额外 flake 输出 |
