{ config, pkgs, lib, ... }:

{

  imports = [
	"${fetchTarball "https://github.com/gmodena/nix-flatpak/archive/main.tar.gz"}/modules/home-manager.nix"
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "paulo_";
  home.homeDirectory = "/home/paulo_";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs;[
	eza
	bat
	ripgrep
	fzf
	fd
	jq
	tldr
	fastfetch
	lazygit
	gh
	go
	nodejs_22
  ];
  programs.git = {
	enable=true;
	settings.user={
		name="StardustArch";
		email="paulojoaocandrinho4@gmail.com";
	};
  };
  programs.zsh = {
	enable=true;
	enableCompletion=true;
	autosuggestion.enable=true;
	syntaxHighlighting.enable=true;
	dotDir = ".config/zsh";
	
	shellAliases ={
		ll="eza -l -g --icons";
		ls="eza --icons";
		cat="bat";
		update="sudo pacman -Syu";
    # --- NIX & HOME MANAGER ALIASES ---
    hms="home-manager switch --flake ~/.config/home-manager#paulo_";
    hmu="nix flake update ~/.config/home-manager && hms";
    nclean="nix-collect-garbage -d";
    hme="cd ~/.config/home-manager && $EDITOR flake.nix"
	};
  };

  programs.starship = {
	enable=true;
	enableZshIntegration=true;
  };

  programs.neovim = {
	enable=true;
	defaultEditor=true;
	viAlias=true;
	vimAlias=true;
  };
  
  services.flatpak = {
	enable=true;
	uninstallUnmanaged=true;
	
	remotes = lib.mkOptionDefault[{
		name="flathub";
		location="https://dl.flathub.org/repo/flathub.flatpakrepo";
		}];
	packages = [
		];
  };  

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/paulo_/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
