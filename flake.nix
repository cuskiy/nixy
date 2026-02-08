{
  description = "Schema-driven configuration framework for NixOS, Darwin, and Home Manager";

  outputs =
    { self }:
    {
      eval = lib: (import ./nix/eval.nix { inherit lib; }).eval;

      templates.minimal = {
        description = "Single NixOS machine";
        path = ./templates/minimal;
      };
    };
}
