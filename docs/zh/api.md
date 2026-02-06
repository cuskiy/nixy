# API 参考

## nixy.eval

主入口，返回 flake outputs 属性集。

```nix
nixy.eval {
  nixpkgs;
  imports ? [ ];
  args ? { };
  exclude ? null;
}
```

## targets

定义某个 target 类型的 host 如何构建。`nixos` 是内置的，其他 target 需要在这里注册。

```nix
targets.darwin = {
  instantiate = { system, modules, specialArgs }: ...;
  output = "darwinConfigurations";
};
```

## rules

构建时检查的断言。任何断言失败都会中止构建并输出对应的错误信息。

```nix
rules = [
  { assertion = config.hosts ? server; message = "server host required"; }
];
```

## perSystem

按系统定义 packages、dev shells、formatter 等输出。

```nix
perSystem = { pkgs, system }: {
  packages.hello = pkgs.hello;
  devShells.default = pkgs.mkShell { };
  formatter = pkgs.nixfmt-rfc-style;
};
```

## flake

任意额外的 flake 输出。

```nix
flake.overlays.default = final: prev: { };
flake.deploy.nodes = { ... };
```

## 生成的输出

Nixy 会产生以下 flake 输出：

- `nixosConfigurations.<n>` 及自定义 target 的输出
- `formatter.<s>`
- `apps.<s>.check`
- 来自 `perSystem` 的 `packages`、`devShells`、`checks`、`legacyPackages`
