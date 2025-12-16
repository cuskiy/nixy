let
  lock = builtins.fromJSON (builtins.readFile ./inputs.lock);
  fetch = name: builtins.fetchTarball lock.${name}.url;
  nixy = import (fetch "nixy");
  nixpkgsSrc = fetch "nixpkgs";
  pkgs = import nixpkgsSrc { };
  nixpkgs = {
    inherit (pkgs) lib;
    legacyPackages.${builtins.currentSystem} = pkgs;
  };
in
nixy.mkConfiguration {
  inherit nixpkgs;
  imports = [ ./. ];
}
