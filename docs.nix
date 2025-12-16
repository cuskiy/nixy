{
  pkgs ? import <nixpkgs> { },
}:
pkgs.stdenv.mkDerivation {
  name = "nixy-docs";
  src = ./.;
  nativeBuildInputs = [ pkgs.mdbook ];
  buildPhase = ''
    mdbook build
  '';
  installPhase = ''
    cp -r book $out
  '';
}
