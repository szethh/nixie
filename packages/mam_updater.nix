{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "mam_updater";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "szethh";
    repo = "mam_updater";
    rev = "main";
    sha256 = "sha256-AeEmXIvZnaBBUyTTdgWOT1f9E6WWGXOF9E0EDbHMfZQ=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out
  '';
}
