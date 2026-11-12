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
      # Nome do utilizador detetado do ambiente, com fallback seguro
      username = if builtins.getEnv "USER" != "" then builtins.getEnv "USER" else "stardust";
    in {
      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # 2. Passa o nix-flatpak e o username para dentro do home.nix
        extraSpecialArgs = { inherit nix-flatpak username; }; 
        modules = [ ./home.nix ];
      };
    };
}