# Hosts

每个 host 代表一台机器。

```nix
{
  hosts.my-machine = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "my-machine";
  };
}
```

## 字段

### system

目标系统字符串。设为 `null` 可以让 nixpkgs 通过 `hostPlatform` 推断。

### target

Nixy 会根据 system 自动推断 target——`*-darwin` 对应 `"darwin"`，其余对应 `"nixos"`。Home Manager 的 host 需要手动指定：

```nix
hosts."alice-home" = {
  system = "x86_64-linux";
  target = "home";
  home.enable = true;
  home.username = "alice";
};
```

### extraModules

为当前 host 额外加载的 NixOS/Darwin/HM 模块：

```nix
hosts.server.extraModules = [
  { services.openssh.enable = true; }
  ./hardware-configuration.nix
];
```

### instantiate

如果需要使用和 target 默认不同的构建器，可以按 host 覆盖：

```nix
hosts.stable-server = {
  system = "x86_64-linux";
  instantiate = { system, modules, specialArgs }:
    inputs.nixpkgs-stable.lib.nixosSystem {
      inherit system modules specialArgs;
    };
};
```
