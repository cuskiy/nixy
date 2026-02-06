# Minimal Setup

Single NixOS machine.

```bash
nix flake init -t github:anialic/nixy#minimal
```

## flake.nix

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

## hosts/my-nixos.nix

```nix
{
  hosts.my-nixos = {
    system = "x86_64-linux";
    base.enable = true;
    base.hostName = "my-nixos";
    base.user = "alice";
    extraModules = [{
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
    }];
  };
}
```

## Build

```bash
nixos-rebuild switch --flake .#my-nixos
```
