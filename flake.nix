{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # darwin stuff
    # darwin.url = "github:LnL7/nix-darwin";
    darwin.url = "git+file:///Users/szeth/dev/forks/nix-darwin?ref=dock-persistent-others";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # nixvirt = {
    #   url = "github:AshleyYakeley/NixVirt/nixpkgs-24.05";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      # url = "github:nix-community/home-manager/release-24.05";
      # using a fork for now
      # due to https://github.com/nix-community/home-manager/issues/5757
      # borgmatic requires linux but it works fine on darwin too
      # so removing the assertion
      url = "github:szethh/home-manager/borgmatic-darwin";
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
      url = "git+file:///Users/szeth/dev/forks/disko?ref=fix-mdadm-symlink";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      home-manager,
      darwin,
      disko,
      ...
    }@inputs:
    let
      systemLinux = "x86_64-linux";
      systemDarwin = "x86_64-darwin";
      pkgsLinux = import nixpkgs {
        system = systemLinux;
        overlays = [ (import ./packages/caddy_plugins.nix) ];
      };
      pkgsLinuxUnstable = import nixpkgs-unstable {
        system = systemLinux;
        overlays = [ (import ./packages/caddy_plugins.nix) ];
      };
      # the overlays are applied in darwin.nix
      pkgsDarwin = import nixpkgs { system = systemDarwin; };
    in
    {
      # nix develop
      devShells.${systemDarwin}.default = pkgsDarwin.mkShell {
        buildInputs = with pkgsDarwin; [
          colmena
          sops
        ];

        # for some reason sops tries to look for the key in ~/Application Support/sops/age/keys.txt
        # https://github.com/getsops/sops/issues/983
        shellHook = ''
          $SHELL
          export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
        '';
      };

      # nix darwin
      darwinConfigurations = {
        mackie = darwin.lib.darwinSystem {
          system = systemDarwin;
          modules = [
            ./darwin
            # i cannot figure this out
            # but it could be useful for building stuff locally on macos instead of on the remote host
            # (import ./darwin/darwin-linux-builder.nix {
            #   inherit nixpkgs;
            #   pkgs = pkgsDarwin;
            #   system = systemLinux;
            # })
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.szeth = import ./home.nix;
              home-manager.backupFileExtension = "nix.bak";

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
              home-manager.extraSpecialArgs = {
                inherit inputs;
              };
            }
          ];
        };
      };

      ## BOOTSTRAP ##
      nixosConfigurations.htz = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/htz/bootstrap.nix
        ];
      };

      # colmena stuff
      colmena = {
        meta = {
          nixpkgs = pkgsLinux;

          nodeNixpkgs = {
            nixvm = pkgsLinuxUnstable; # these two need to be the same, since we are building the same package and the hash needs to be the same
          };

          specialArgs = {
            inherit inputs;
            pkgsStable = pkgsLinux;
            pkgsUnstable = pkgsLinuxUnstable;
          };
        };

        defaults = {
          imports = [
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };

        nixie = import ./hosts/nixie;

        htz = import ./hosts/htz;

        nixvm = import ./hosts/nixvm;

        flat = import ./hosts/flat;

        # (inputs // { pkgs-unstable = pkgsLinuxUnstable; });
      };
    };
}
