{
  description = "Nixy — Lightweight NixOS/Darwin/Home Manager framework";

  outputs =
    { self }:
    {
      templates = {
        minimal = {
          description = "Minimal NixOS configuration";
          path = ./templates/minimal;
        };
        complex = {
          description = "Multi-platform with deploy-rs, custom targets, and assertions";
          path = ./templates/complex;
        };
      };

      eval =
        {
          nixpkgs,
          imports ? [ ],
          args ? { },
          exclude ? null,
        }:
        let
          nixy = import ./nix/eval.nix { inherit (nixpkgs) lib; };
        in
        nixy.eval {
          inherit nixpkgs imports args exclude;
        };
    };
}
