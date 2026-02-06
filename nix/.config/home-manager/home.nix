{ config, pkgs, lib,nix-flatpak, ... }:

let
  # ============================================================
  # CENTRAL DE TEMAS (O teu "Switch" de cores)
  # ============================================================
  
  # 1. Escolhe o teu tema aqui: "nord", "aizome" ou "gruvbox"
  selectedTheme = "nord"; 

  themes = {
    nord = {
      bg0 = "2e3440"; bg1 = "3b4252"; bg2 = "434c5e"; bg3 = "4c566a";
      fg0 = "d8dee9"; fg1 = "e5e9f0"; fg2 = "eceff4";
      accent0 = "8fbcbb"; accent1 = "88c0d0"; accent2 = "81a1c1"; accent3 = "5e81ac";
      red = "bf616a"; orange = "d08770"; yellow = "ebcb8b"; green = "a3be8c"; purple = "b48ead";
    };
    aizome = {
      bg0 = "101d31"; bg1 = "16263e"; bg2 = "2b507e"; bg3 = "3b4b64";
      fg0 = "dcdcdc"; fg1 = "e2e2e2"; fg2 = "ffffff";
      accent0 = "7d563e"; accent1 = "9a6b4d"; accent2 = "3d6a9e"; accent3 = "244066";
      red = "a65e6a"; orange = "c4a068"; yellow = "ad8f5e"; green = "8a9a7b"; purple = "7c6a8a";
    };
    gruvbox = {
      bg0 = "282828"; bg1 = "32302f"; bg2 = "45403d"; bg3 = "5a524c";
      fg0 = "dfbf8e"; fg1 = "d4be98"; fg2 = "ddc7a1";
      accent0 = "a9b665"; accent1 = "d8a657"; accent2 = "7daea3"; accent3 = "89b482";
      red = "ea6962"; orange = "e78a4e"; yellow = "d8a657"; green = "a9b665"; purple = "d3869b";
    };
  };

  # Esta variável 'colors' será usada em todo o resto do ficheiro
  colors = themes.${selectedTheme};

in

{

  imports = [
    nix-flatpak.homeManagerModules.nix-flatpak
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
  # ============================================================
  # GERAÇÃO DE FICHEIROS DE CORES (Hyprland, Waybar, Rofi)
  # ============================================================
  
  # Gera o colors.conf para o Hyprland
  home.file.".config/hypr/colors.conf".text = ''
    $bg0 = rgba(${colors.bg0}ff)
    $bg3 = rgba(${colors.bg3}ff)
    $fg0 = rgba(${colors.fg0}ff)
    $accent1 = rgba(${colors.accent1}ff)
    $accent3 = rgba(${colors.accent3}ff)
    $shadow_col = rgba(00000055)
  '';

  # Gera o colors.css para Waybar e SwayNC
  home.file.".config/waybar/colors.css".text = ''
    @define-color bg0 #${colors.bg0};
    @define-color bg1 #${colors.bg1};
    @define-color bg3 #${colors.bg3};
    @define-color fg0 #${colors.fg0};
    @define-color fg2 #${colors.fg2};
    @define-color accent1 #${colors.accent1};
    @define-color accent3 #${colors.accent3};
    @define-color red #${colors.red};
    @define-color yellow #${colors.yellow};
    @define-color green #${colors.green};
  '';

  # Gera o colors.rasi para o Rofi
  home.file.".config/rofi/colors.rasi".text = ''
    * {
        bg:      #${colors.bg0}f2;
        bg-alt:  #${colors.bg1};
        bg-sel:  #${colors.bg2};
        fg:      #${colors.fg0};
        accent:  #${colors.accent1};
        muted:   #${colors.bg3};
    }
  '';

home.file = {
  # O Nix vai buscar o ficheiro ao teu repo e cria o link em ~/.config/hypr/
  ".config/hypr/hyprland.conf".source = ../../../hypr/.config/hypr/hyprland.conf;
  ".config/hypr/keybinds.conf".source = ../../../hypr/.config/hypr/keybinds.conf;
  ".config/hypr/autostart.conf".source = ../../../hypr/.config/hypr/autostart.conf;
  ".config/rofi/config.rasi".source = ../../../rofi/.config/rofi/config.conf;
  ".config/waybar/config.jsonc".source = ../../../waybar/.config/waybar/config.jsonc;
  ".config/swaync/config.jsonc".source = ../../../swaync/.config/swaync/config.jsonc;
};
  # ============================================================
  # PROGRAMAS CONFIGURADOS
  # ============================================================

  home.packages = with pkgs; [
    eza bat ripgrep fzf fd jq tldr fastfetch lazygit gh go nodejs_22 nerd-fonts.jetbrains-mono
  ];
  xdg.configFile."kitty/kitty.conf".force = true;
  fonts.fontconfig.enable = true;
  programs.kitty = {
    enable = true;
    font = { name = "JetBrainsMono Nerd Font"; size = 12.0; };
    settings = {
      "font_family" = "JetBrainsMono Nerd Font";
      background_opacity = "0.85";
      window_padding_width = 10;
      confirm_os_window_close = 0;
      hide_window_decorations = "yes";
      cursor = "#${colors.accent1}";
      cursor_text_color = "#${colors.bg0}";
      foreground = "#${colors.fg0}";
      background = "#${colors.bg0}";
      selection_background = "#${colors.accent1}";
      # Paleta ANSI
      color0 = "#${colors.bg1}"; color8 = "#${colors.bg3}";
      color1 = "#${colors.red}"; color9 = "#${colors.red}";
      color2 = "#${colors.green}"; color10 = "#${colors.green}";
      color3 = "#${colors.yellow}"; color11 = "#${colors.yellow}";
      color4 = "#${colors.accent2}"; color12 = "#${colors.accent2}";
      color5 = "#${colors.purple}"; color13 = "#${colors.purple}";
      color6 = "#${colors.accent1}"; color14 = "#${colors.accent0}";
      color7 = "#${colors.fg1}"; color15 = "#${colors.fg2}";
    };
  };

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
	dotDir=config.home.homeDirectory;
	shellAliases ={
		ll="eza -l -g --icons";
		ls="eza --icons";
		cat="bat";
		update="sudo pacman -Syu";
    # --- NIX & HOME MANAGER ALIASES ---
    hms = "home-manager switch -b backup --flake ~/.config/home-manager#paulo_";
    hmu="nix flake update ~/.config/home-manager && hms";
    nclean="nix-collect-garbage -d";
    hme="cd ~/.config/home-manager && $EDITOR flake.nix";
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
