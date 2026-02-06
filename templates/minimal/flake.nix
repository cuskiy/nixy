{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
