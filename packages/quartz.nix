{ pkgs ? import <nixpkgs> { } }:

let
  version = "4.0.8";
  src = pkgs.fetchFromGitHub {
    owner = "jackyzha0";
    repo = "quartz";
    rev = "v${version}";
    sha256 = "sha256-bdn3ovklgAZt1mlYSofEwAjb6j4EAlZGK0ie1AeR9do=";
  };
in pkgs.buildNpmPackage {
  name = "quartz";

  npmDepsHash = "sha256-H+G9KAn8PXtGM81TpHjNrmfWrORI4e/fwFLZqR+E5Ls=";
  dontNpmBuild = true;

  src = src;

  #   buildInputs = [ pkgs.nodejs ];

  #   npmPackFlags = [ "--ignore-scripts --loglevel=verbose" ];

  #   buildPhase = ''

  #   '';

  installPhase = ''
    runHook preInstall
    npmInstallHook
    # npx quartz create
    runHook postInstall
    mkdir -p $out/bin
    cp -r * $out/bin
  '';

  meta = with pkgs.lib; {
    description =
      "🌱 a fast, batteries-included static-site generator that transforms Markdown content into fully functional websites";
    homepage = "https://github.com/jackyzha0/quartz";
    license = licenses.mit;
    maintainers = with maintainers; [ szethh ];
  };
}
