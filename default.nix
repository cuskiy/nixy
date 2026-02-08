# Traditional Nix compatibility.
# Usage: (import <nixy> { inherit lib; }).eval { imports = [ ./. ]; }
{ lib }: import ./nix/eval.nix { inherit lib; }
