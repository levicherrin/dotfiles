{
  description = "Levi's cross-platform dotfiles (WSL2, Debian GNU/Linux, and macOS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, nix-homebrew }:
    let
      # Configured username - bootstrap.sh will auto-align this with your user
      user = "levi";
      linuxPkgs = nixpkgs.legacyPackages.x86_64-linux;
      linuxArmPkgs = nixpkgs.legacyPackages.aarch64-linux;
    in
    {
      # Standalone Home Manager for Linux & WSL2 (x86_64 and ARM)
      homeConfigurations = {
        "linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { inherit user inputs; isDarwin = false; };
          modules = [
            ./home.nix
            {
              home.username = user;
              home.homeDirectory = "/home/${user}";
            }
          ];
        };
        "linux-arm" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxArmPkgs;
          extraSpecialArgs = { inherit user inputs; isDarwin = false; };
          modules = [
            ./home.nix
            {
              home.username = user;
              home.homeDirectory = "/home/${user}";
            }
          ];
        };
      };

      # macOS configuration via nix-darwin + home-manager
      darwinConfigurations = {
        "mac" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit user inputs; isDarwin = true; };
          modules = [
            ./darwin.nix
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit user inputs; isDarwin = true; };
              home-manager.users.${user} = import ./home.nix;
            }
          ];
        };
      };
    };
}
