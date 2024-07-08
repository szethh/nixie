{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # darwin stuff
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
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
  };
  outputs = { nixpkgs, sops-nix, home-manager, darwin, ... }@inputs:
  let
    systemLinux = "x86_64-linux";
    systemDarwin = "x86_64-darwin";
    pkgsLinux = import nixpkgs { system = systemLinux; overlays = [ (import ./packages/caddy_plugins.nix) ]; };
    pkgsDarwin = import nixpkgs { system = systemDarwin; };
  in
  {
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

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
            home-manager.extraSpecialArgs = {
              inherit inputs;
            };
          }
        ];
      };
    };

    # colmena stuff
    colmena = {
      meta = {
        nixpkgs = pkgsLinux;

        # specialArgs = {
        #   inherit inputs;
        # };
      };

      defaults = {
        imports = [
          sops-nix.nixosModules.sops
        ];
      };

      nixie = import ./hosts/nixie;
    };
  };
}