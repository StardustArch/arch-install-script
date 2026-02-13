{
  description = "Configuração Home Manager do Paulo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 1. Adiciona o nix-flatpak aqui
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { nixpkgs, home-manager, nix-flatpak, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."stardust" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # 2. Passa o nix-flatpak para dentro do home.nix
        extraSpecialArgs = { inherit nix-flatpak; }; 
        modules = [ ./home.nix ];
      };
    };
}