{
  description = "Nixy - A minimal NixOS/Darwin/Home Manager framework";

  outputs =
    { self }:
    {
      templates = {
        minimal = {
          description = "Minimal NixOS configuration";
          path = ./templates/minimal;
        };
        multi-platform = {
          description = "NixOS + nix-darwin + Home Manager";
          path = ./templates/multi-platform;
        };
        deploy-rs = {
          description = "With deploy-rs for remote deployment";
          path = ./templates/deploy-rs;
        };
        without-flakes = {
          description = "Traditional configuration without flakes";
          path = ./templates/without-flakes;
        };
      };

      lib = import ./nix/eval.nix;
      mkFlake = import ./nix/mkFlake.nix;
      mkConfiguration = import ./nix/mkConfiguration.nix;
    };
}
