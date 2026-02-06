# Complex Setup

Multi-platform with deploy-rs, custom targets, per-system outputs, and assertions.

```bash
nix flake init -t github:anialic/nixy#complex
```

## flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
    deploy-rs.url = "github:serokell/deploy-rs";
    nixy.url = "github:anialic/nixy";
  };

  outputs = { nixpkgs, nixy, ... }@inputs: nixy.eval {
    inherit nixpkgs;
    imports = [ ./. ];
    args = { inherit inputs; };
  };
}
```

## targets.nix

```nix
{ inputs, nixpkgs, ... }:
{
  targets.darwin = {
    instantiate = { system, modules, specialArgs }:
      inputs.nix-darwin.lib.darwinSystem { inherit system modules specialArgs; };
    output = "darwinConfigurations";
  };

  targets.home = {
    instantiate = { system, modules, specialArgs }:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = modules;
        extraSpecialArgs = specialArgs;
      };
    output = "homeConfigurations";
  };
}
```

## modules/base.nix

```nix
{ mkStr, ... }:
{
  schema.base = {
    hostName = mkStr null;
    user = mkStr null;
    timeZone = mkStr "UTC";
  };

  modules.base.load = [({ host, ... }: {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.hostName = host.base.hostName;
    time.timeZone = host.base.timeZone;
    users.users.${host.base.user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      initialPassword = "changeme";
    };
    system.stateVersion = "26.05";
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  })];
}
```

## modules/darwin.nix

```nix
{ mkStr, ... }:
{
  schema.darwin.hostName = mkStr null;

  modules.darwin.load = [({ host, ... }: {
    networking.hostName = host.darwin.hostName;
    system.stateVersion = 6;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  })];
}
```

## modules/home.nix

```nix
{ mkStr, ... }:
{
  schema.home = {
    username = mkStr null;
    directory = mkStr "/home";
  };

  modules.home.load = [({ host, ... }: {
    home.username = host.home.username;
    home.homeDirectory = "${host.home.directory}/${host.home.username}";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
  })];
}
```

## modules/deploy.nix

```nix
{ mkStr, ... }:
{
  schema.deploy = {
    hostname = mkStr null;
    sshUser = mkStr "root";
  };

  modules.deploy.load = [ ];
}
```

## custom.nix

```nix
{ lib, config, inputs, ... }:
let
  deployHosts = lib.filterAttrs (_: h: h.deploy.enable or false) config.hosts;
in {
  flake.deploy.nodes = lib.mapAttrs (name: host:
    let cfg = config.flake.nixosConfigurations.${name};
    in {
      hostname = host.deploy.hostname;
      sshUser = host.deploy.sshUser;
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.${host.system}.activate.nixos cfg;
      };
    }
  ) deployHosts;

  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-rfc-style;
    packages.greeting = pkgs.writeShellScriptBin "greeting" ''echo "Hello from nixy"'';
  };

  rules = [{
    assertion = config.hosts ? server;
    message = "a 'server' host must be defined";
  }];
}
```

## hosts/hosts.nix

```nix
{
  hosts.server = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "server";
    base.user = "admin";
    deploy.enable = true;
    deploy.hostname = "192.168.1.100";
    deploy.sshUser = "deploy";
    extraModules = [{
      fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
      fileSystems."/boot" = { device = "/dev/disk/by-label/boot"; fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ]; };
      services.openssh.enable = true;
    }];
  };

  hosts.macbook = {
    system = "aarch64-darwin";
    darwin.enable = true;
    darwin.hostName = "macbook";
  };

  hosts."alice-home" = {
    system = "x86_64-linux";
    target = "home";
    home.enable = true;
    home.username = "alice";
  };
}
```

## Commands

```bash
nixos-rebuild switch --flake .#server
nix run github:serokell/deploy-rs -- .#server
nix run .#check
nix run .#greeting
```
