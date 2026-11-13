{
  description = "Configuração Home Manager do Stardust";

  inputs = {
    # Canal estável, alinhado com home.stateVersion = "25.11".
    # O flake.lock fixa o commit exacto; só muda com `nix flake update`.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # Nome do utilizador detetado do ambiente, com fallback seguro
      username = if builtins.getEnv "USER" != "" then builtins.getEnv "USER" else "stardust";
    in {
      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit username; };
        modules = [ ./home.nix ];
      };
    };
}
