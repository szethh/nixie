{
  pkgs ? import <nixpkgs> { },
}:

let
  nodePackages = pkgs.nodePackages;
in
pkgs.buildNpmPackage rec {
  pname = "home-tools";
  version = "1.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "szethh";
    repo = "home-tools";
    rev = "da1a6254496fa18aa92e3ab983410b480a217151";
    sha256 = "sha256-7W80cOxifvH8O6kOvLJ6Q7NOEm8n3C0n75D6SUQdYGA=";
  };

  npmDepsHash = "sha256-RFXeCmmvMfwljs2+CgX7HeiGndrqikfRHdtcSBLziXk=";

  # buildInputs = [ pkgs.nodejs ];

  buildPhase = ''
    npm install
    npm run build
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/${pname}
    cp -r . $out/lib/node_modules/${pname}
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Home Tools";
    homepage = "https://github.com/szethh/home-tools";
    license = licenses.mit;
    maintainers = with maintainers; [ szethh ];
  };
}
