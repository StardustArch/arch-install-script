{ config, pkgs, lib, ... }:

{
  # Pacotes CLI e essencial (fonte Nerd vem do pacman; power-menu
  # removido: usava rofi + hyprlock, substituídos pelo Noctalia).
  home.packages = (with pkgs; [
    eza bat ripgrep fzf fd jq tldr fastfetch lazygit gh
    grim slurp swappy wl-clipboard dconf
    glib gsettings-desktop-schemas
  ]);
}
