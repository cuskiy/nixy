# Traditional Nix compatibility.
# Usage: (import <nixy>).eval { inherit lib; imports = [ ./. ]; }
{ eval = import ./nix/eval.nix; }
