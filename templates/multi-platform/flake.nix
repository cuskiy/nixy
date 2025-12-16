{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
    nixy.url = "github:anialic/nixy";
  };

  outputs =
    { nixpkgs, nixy, ... }@inputs:
    nixy.mkFlake {
      inherit nixpkgs;
      imports = [ ./. ];
      args = { inherit inputs; };
    };
}
