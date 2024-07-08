
build-colmena:
    colmena build

apply-colmena:
    colmena apply

install-nix:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Initialize darwin flake using:
init-darwin:
    nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/.config/nix

build-darwin:
    darwin-rebuild switch --flake .

secrets:
    sops secrets/secrets.yaml
