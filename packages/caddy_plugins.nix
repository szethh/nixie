# this comes from https://discourse.nixos.org/t/build-caddy-with-modules-in-devenv-shell/25125/4
# also check out  https://github.com/NixOS/nixpkgs/pull/191883#issuecomment-1250652290
# this is cleaner but does not seem to work
# { pkgs, config, plugins ? [], ... }:

# with pkgs;

# stdenv.mkDerivation rec {
#     pname = "caddy";
#     version = "2.7.6";
#     dontUnpack = true;

#     nativeBuildInputs = [ git go xcaddy ];

#     configurePhase = ''
#         export GOCACHE=$TMPDIR/go-cache
#         export GOPATH="$TMPDIR/go"
#     '';

#     buildPhase = let
#         pluginArgs = lib.concatMapStringsSep " " (plugin: "--with ${plugin}") plugins;
#     in ''
#         runHook preBuild
#         ${xcaddy}/bin/xcaddy build "v${version}" ${pluginArgs}
#         runHook postBuild
#     '';

#     installPhase = ''
#         runHook preInstall
#         mkdir -p $out/bin
#         mv caddy $out/bin
#         runHook postInstall
#     '';
# }

# this one comes from https://noah.masu.rs/posts/caddy-cloudflare-dns/
_final: prev:

let
  plugins =
    [ "github.com/caddy-dns/cloudflare" "github.com/caddy-dns/acmedns" ];
  goImports =
    prev.lib.flip prev.lib.concatMapStrings plugins (pkg: "   _ \"${pkg}\"\n");
  goGets = prev.lib.flip prev.lib.concatMapStrings plugins
    (pkg: "go get ${pkg}\n      ");
  main = ''
    package main
    import (
    	caddycmd "github.com/caddyserver/caddy/v2/cmd"
    	_ "github.com/caddyserver/caddy/v2/modules/standard"
    ${goImports}
    )
    func main() {
    	caddycmd.Main()
    }
  '';

in {
  caddy-cloudflare = prev.buildGo122Module {
    pname = "caddy-cloudflare";
    version = prev.caddy.version;
    runVend = true;

    subPackages = [ "cmd/caddy" ];

    src = prev.caddy.src;

    # so first you try it with a fake hash, and it will fail and tell you the real hash
    # vendorHash = "sha256:${prev.lib.fakeSha256}";
    vendorHash = "sha256-tPEsp7rya0rzaKZW2acJ5Sf7OwbswaIEe9GJJmL4JG0=";

    overrideModAttrs = (_: {
      preBuild = ''
        echo '${main}' > cmd/caddy/main.go
        ${goGets}
      '';
      postInstall = "cp go.sum go.mod $out/ && ls $out/";
    });

    postPatch = ''
      echo '${main}' > cmd/caddy/main.go
      cat cmd/caddy/main.go
    '';

    postConfigure = ''
      cp vendor/go.sum ./
      cp vendor/go.mod ./
    '';

    meta = with prev.lib; {
      homepage = "https://caddyserver.com";
      description =
        "Fast, cross-platform HTTP/2 web server with automatic HTTPS";
      license = licenses.asl20;
      maintainers = with maintainers; [ Br1ght0ne techknowlogick ];
    };
  };
}
