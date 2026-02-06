<p align="center">
  <img src="https://raw.githubusercontent.com/anialic/nixy/main/.github/assets/logo.svg" width="200" alt="Nixy">
</p>

<p align="center">
  轻量级 NixOS/Darwin/Home Manager 框架
</p>

<p align="center">
  <a href="https://anialic.github.io/nixy">文档</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#模板">模板</a>
</p>

---

## 快速开始

```bash
nix flake init -t github:anialic/nixy#minimal
```

## 概述

Nixy 围绕 **hosts** 和 **modules** 组织 NixOS 配置：

```nix
{ mkStr, mkPort, ... }:
{
  schema.ssh.port = mkPort 22;

  modules.ssh.load = [({ host, ... }: {
    services.openssh.enable = true;
    services.openssh.ports = [ host.ssh.port ];
  })];
}
```

主机声明需要哪些模块：

```nix
hosts.server = {
  system = "x86_64-linux";
  base.enable = true;
  ssh.enable = true;
};
```

## 使用

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixy.url = "github:anialic/nixy";
  };

  outputs = { nixpkgs, nixy, ... }@inputs: nixy.eval {
    inherit nixpkgs;
    imports = [ ./. ];
    args = { inherit inputs; };
  };
}
```

## 模板

| 模板 | 说明 |
|------|------|
| `minimal` | 单机 NixOS |
| `complex` | 多平台，含 disko 和 deploy-rs |

```bash
nix flake init -t github:anialic/nixy#<template>
```

## 许可

Apache-2.0
