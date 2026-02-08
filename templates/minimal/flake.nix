{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixy.url = "github:anialic/nixy";
  };

  outputs =
    { nixpkgs, nixy, ... }@inputs:
    let
      lib = nixpkgs.lib;
      cluster = nixy.eval lib {
        imports = [ ./. ];
        args = { inherit inputs; };
      };
    in
    {
      nixosConfigurations = lib.mapAttrs (
        _: node:
        lib.nixosSystem {
          system = node.meta.system;
          modules = [ node.module ];
        }
      ) cluster.nodes;
    };
}
