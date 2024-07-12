{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # darwin stuff
    # darwin.url = "github:LnL7/nix-darwin";
    darwin.url =
      "git+file:///Users/szeth/dev/nix-darwin?ref=dock-persistent-others";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      # url = "github:nix-community/disko";
      url = "git+file:///Users/szeth/dev/disko?ref=fix-mdadm-symlink";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, sops-nix, home-manager, darwin, disko, ... }@inputs:
    let
      systemLinux = "x86_64-linux";
      systemDarwin = "x86_64-darwin";
      pkgsLinux = import nixpkgs {
        system = systemLinux;
        overlays = [ (import ./packages/caddy_plugins.nix) ];
      };
      pkgsDarwin = import nixpkgs { system = systemDarwin; };
    in {
      # nix develop
      devShells.${systemDarwin}.default = pkgsDarwin.mkShell {
        buildInputs = with pkgsDarwin; [ colmena sops ];

        # for some reason sops tries to look for the key in ~/Application Support/sops/age/keys.txt
        # https://github.com/getsops/sops/issues/983
        shellHook = ''
          export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
        '';
      };

      # nix darwin
      darwinConfigurations = {
        mackie = darwin.lib.darwinSystem {
          system = systemDarwin;
          modules = [
            ./darwin
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.szeth = import ./home.nix;
              home-manager.backupFileExtension = "nix.bak";

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };

      ## BOOTSTRAP ##
      nixosConfigurations.htz = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [ disko.nixosModules.disko ./hosts/htz/bootstrap.nix ];
      };

      # colmena stuff
      colmena = {
        meta = {
          nixpkgs = pkgsLinux;

          # specialArgs = {
          #   inherit inputs;
          # };
        };

        defaults = { imports = [ sops-nix.nixosModules.sops ]; };

        nixie = import ./hosts/nixie;

        htz = import ./hosts/htz;
      };
    };
}
