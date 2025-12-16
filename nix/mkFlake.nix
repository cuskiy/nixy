{
  nixpkgs,
  imports ? [ ],
  args ? { },
  exclude ? null,
}:
let
  nixy = import ./eval.nix { inherit (nixpkgs) lib; };
in
nixy.eval {
  inherit
    nixpkgs
    args
    exclude
    imports
    ;
}
