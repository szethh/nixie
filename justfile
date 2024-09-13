
build-colmena:
    colmena build

apply-colmena:
    colmena apply

install-nix:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Initialize darwin flake using:
init-darwin:
    nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .

build-darwin:
    darwin-rebuild switch --flake .

secrets:
    sops secrets/secrets.yaml

gc:
    nix-collect-garbage -d

# Bootstrap
bootstrap host ip:
    nix run github:johanot/nixos-anywhere?ref=hetzner -- \
        root@{{ip}} \
        --flake .#{{host}} \

# this can only be run on a nixos host
vm host:
    nix run github:nix-community/nixos-generators -- --format proxmox --configuration hosts/{{host}}/proxmox.nix