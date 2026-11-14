{ config, pkgs, lib, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11"; # Não alterar sem ler as release notes.

  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/editor.nix
    ./modules/shell.nix
    ./modules/theming.nix
    ./modules/desktop.nix
  ];

  # ============================================================
  # GTK/Qt: fixo mínimo no Home Manager (cores vêm do Noctalia)
  # ============================================================

  home.sessionVariables = {
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$HOME/.local/share:/usr/share:$XDG_DATA_DIRS";
  };

  dconf.enable = true;
  nixpkgs.config.allowUnfree = true;
  fonts.fontconfig.enable = true;

  # ============================================================
  # PROGRAMAS
  # ============================================================
  programs.home-manager.enable = true;
}
