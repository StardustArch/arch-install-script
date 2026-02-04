{
  description = "Configuração Home Manager do Paulo";

  inputs = {
    # Aqui a gente fixa a fonte dos pacotes
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux"; # O sistema do seu Latitude
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # "paulo" é o nome do seu usuário
      homeConfigurations."paulo_" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ]; # Ele vai ler o seu home.nix que já existe aí do lado
      };
    };
}