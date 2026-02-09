{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixy.url = "github:anialic/nixy";
  };

  outputs =
    { nixpkgs, nixy, ... }@inputs:
    let
      cluster = nixy.eval {
        inherit (nixpkgs) lib;
        imports = [ ./. ];
        args = { inherit inputs; };
      };
    in
    {
      nixosConfigurations = nixpkgs.lib.mapAttrs (
        _: node:
        nixpkgs.lib.nixosSystem {
          system = node.schema.base.system;
          modules = [ node.module ];
        }
      ) cluster.nodes;
    };
}
