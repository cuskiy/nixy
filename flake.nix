{
  description = "Schema-driven configuration framework for NixOS, Darwin, and Home Manager";

  outputs =
    { self, ... }:
    let
      nixy = import ./nix/eval.nix;
    in
    {
      # Usage: nixy.eval nixpkgs.lib { imports = [ ./. ]; args = { ... }; }
      eval = lib: (nixy { inherit lib; }).eval;

      templates.minimal = {
        description = "Single NixOS machine";
        path = ./templates/minimal;
      };
    };
}
