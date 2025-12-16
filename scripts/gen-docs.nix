let
  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  pkgs = import nixpkgs { };
  nixy = import ../nix/eval.nix { inherit (pkgs) lib; };

  helpersDoc = pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (name: desc: "| `${name}` | ${desc} |") nixy.meta.helpers
  );

in
pkgs.writeText "helpers.md" ''
  # Option Helpers

  Helpers are available as framework module arguments.

  | Helper | Description |
  |--------|-------------|
  ${helpersDoc}

  ## Usage

  ```nix
  { mkStr, mkBool, mkList, lib, ... }:
  {
    modules.example.options = {
      name = mkStr null;
      enabled = mkBool true;
      ports = mkList lib.types.port [ 80 443 ];
    };
  }
  ```
''
