{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixy.url = "github:anialic/nixy";

  outputs =
    { nixpkgs, nixy, ... }@inputs:
    nixy.mkFlake {
      inherit nixpkgs;
      imports = [ ./. ];
      args = { inherit inputs; };
    };
}
