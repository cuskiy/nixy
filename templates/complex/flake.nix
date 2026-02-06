{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
    deploy-rs.url = "github:serokell/deploy-rs";
    disko.url = "github:nix-community/disko";
    nixy.url = "github:anialic/nixy";
  };

  outputs =
    { nixpkgs, nixy, ... }@inputs:
    nixy.eval {
      inherit nixpkgs;
      imports = [ ./. ];
      args = { inherit inputs; };
    };
}
