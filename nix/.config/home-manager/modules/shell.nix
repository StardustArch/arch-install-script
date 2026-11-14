{ config, pkgs, lib, username, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    dotDir = config.home.homeDirectory;
    initContent = ''
      fastfetch
    '';
    shellAliases = {
      ll = "eza -l -g --icons";
      ls = "eza --icons";
      cat = "bat";
      update = "sudo pacman -Syu";
      hms = "home-manager switch -b backup --impure --flake ~/arch-install-script/nix/.config/home-manager#${username}";
      hmu = "nix flake update --flake ~/arch-install-script/nix/.config/home-manager && hms";
      nclean = "nix-collect-garbage -d";
      hme = "cd ~/arch-install-script/nix/.config/home-manager && $EDITOR flake.nix";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    baseIndex = 1;
    prefix = "C-a";
    keyMode = "vi";
    plugins = with pkgs; [
      tmuxPlugins.cpu
      tmuxPlugins.yank
      tmuxPlugins.resurrect
    ];
    extraConfig = ''
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };
}
