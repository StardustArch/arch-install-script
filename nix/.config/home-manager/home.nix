{ config, pkgs, lib,nix-flatpak, ... }:

let
  # ============================================================
  # CENTRAL DE TEMAS (O teu "Switch" de cores)
  # ============================================================
  
  # 1. Escolhe o teu tema aqui: "nord", "aizome" ou "gruvbox"
  rawTheme = builtins.readFile "/home/stardust/.cache/current_theme";
  selectedTheme = lib.removeSuffix "\n" rawTheme;

# --- 2. MAPEAMENTO DE TEMAS GTK ---
  # Aqui definimos qual pacote GTK corresponde ao nosso tema
  gtkThemeConfig = {
    nord = {
      pkg = pkgs.nordic;
      name = "Nordic";
    };
    aizome = {
      pkg = pkgs.tokyonight-gtk-theme; # O mais parecido com Aizome
      name = "Tokyonight-Dark";
    };
    gruvbox = {
      pkg = pkgs.gruvbox-dark-gtk;
      name = "Gruvbox-Dark-B";
    };
  };

  # Seleciona a configuração baseada no tema atual
  currentGtkTheme = gtkThemeConfig.${selectedTheme};

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

# --- 2. SCRIPT: POWER MENU (ROFI) ---
  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    # Opções com ícones Nerd Fonts
    shutdown="⏻ Desligar"
    reboot="⟳ Reiniciar"
    lock="🔒 Bloquear"
    logout="⇠ Sair"
    
    # Chama o Rofi
    selected=$(echo -e "$lock\n$logout\n$reboot\n$shutdown" | rofi -dmenu -p "Energia" -theme-str 'window {width: 300px;}')

    case $selected in
      "$shutdown") systemctl poweroff ;;
      "$reboot") systemctl reboot ;;
      "$lock") pidof hyprlock || hyprlock ;;
      "$logout") hyprctl dispatch exit ;;
    esac
  '';
# --- 3. SCRIPT: WALL MANAGER (Versão ROFI) ---
  wall-manager = pkgs.writeShellApplication {
    name = "wall-manager";
    runtimeInputs = with pkgs; [ swaybg coreutils findutils procps gnused ];
    text = ''
      BASE_DIR="/home/stardust/arch-install-script/hypr/.config/hypr/wallpapers"
      THEME_FILE="$HOME/.cache/current_theme"
      
      # Função de Aplicação (Mantida igual, só muda a interface)
      apply_wall() {
          local wall="$1"
          [ -z "$wall" ] && exit 0
          
          # Aplica wallpaper
          pkill swaybg || true
          nohup swaybg -i "$wall" -m fill > /dev/null 2>&1 &
          
          # Deteta tema pela pasta
          NEW_THEME=$(basename "$(dirname "$wall")")
          CURRENT_THEME=$(cat "$THEME_FILE")
          
          # Atualiza se mudou
          if [ "$NEW_THEME" != "$CURRENT_THEME" ]; then
              echo "$NEW_THEME" > "$THEME_FILE"
              # Chama o script do VSCode (se existir)
              ~/.config/hypr/scripts/vscode-theme.sh "$NEW_THEME" || true
          fi
      }

      ACTION="${1:-select}"
      CURRENT_THEME=$(cat "$THEME_FILE" 2>/dev/null || echo "aizome")
      TARGET_DIR="$BASE_DIR/$CURRENT_THEME"

      case "$ACTION" in
          "static")
              # Apenas reaplica o wallpaper baseado no tema atual da cache
              # Ideal para o 'exec-once' no Hyprland
              log "Aplicando wallpaper estático para o tema: $CURRENT_THEME"
              RANDOM_WALL=$(find "$TARGET_DIR" -maxdepth 1 -type f | shuf -n 1)
              if [ -n "$RANDOM_WALL" ]; then
                  apply_wall "$RANDOM_WALL"
              fi
              ;;

          "select")
              # Usa Rofi para listar ficheiros na pasta do tema atual
              SELECTED=$(find "$TARGET_DIR" -maxdepth 1 -type f -printf "%f\n" | sort | rofi -dmenu -p "Wallpaper ($CURRENT_THEME)" -format 's')
              if [ -n "$SELECTED" ]; then
                  apply_wall "$TARGET_DIR/$SELECTED"
              fi
              ;;

          "switch")
              # Muda o tema inteiro via Rofi
              NEW_THEME=$(find "$BASE_DIR" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort | rofi -dmenu -p "Mudar Tema")
              if [ -n "$NEW_THEME" ]; then
                  echo "$NEW_THEME" > "$THEME_FILE"
                  
                  # Escolhe um wallpaper aleatório desse tema
                  RANDOM_WALL=$(find "$BASE_DIR/$NEW_THEME" -type f | shuf -n 1)
                  apply_wall "$RANDOM_WALL"
                  
                  notify-send "Tema alterado para $NEW_THEME" "Corre 'set-theme $NEW_THEME' para atualizar cores do sistema."
              fi
              ;;
      esac
    '';
  };
in


{

  imports = [
    nix-flatpak.homeManagerModules.nix-flatpak
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "stardust";
  home.homeDirectory = "/home/stardust";

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
    $bg1 = rgba(${colors.bg1}ff)
    $bg3 = rgba(${colors.bg3}ff)
    $fg0 = rgba(${colors.fg0}ff)
    $fg2 = rgba(${colors.fg2}ff)
    $accent1 = rgba(${colors.accent1}ff)
    $accent2 = rgba(${colors.accent2}ff)
    $accent3 = rgba(${colors.accent3}ff)
    $shadow_col = rgba(00000055)
    $tk_bg = 0xff${colors.bg0}
    $tk_base = 0xff${colors.bg1}
    $tk_accent = 0xff${colors.accent1}
    $tk_text = 0xff${colors.fg0}
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

bg: #${colors.bg0}f2;

bg-alt: #${colors.bg1};

bg-sel: #${colors.bg2};

fg: #${colors.fg0};

accent: #${colors.accent1};

muted: #${colors.bg3};

}

'';

home.file = {
  # O Nix vai buscar o ficheiro ao teu repo e cria o link em ~/.config/hypr/
  ".config/hypr/hyprland.conf".source = ../../../hypr/.config/hypr/hyprland.conf;
  ".config/hypr/keybinds.conf".source = ../../../hypr/.config/hypr/keybinds.conf;
  ".config/hypr/autostart.conf".source = ../../../hypr/.config/hypr/autostart.conf;
  ".config/hypr/hyprtoolkit.conf".source = ../../../hypr/.config/hypr/hyprtoolkit.conf;
  ".config/hypr/hyprlock.conf".source = ../../../hypr/.config/hypr/hyprlock.conf;
  ".config/hypr/hypridle.conf".source = ../../../hypr/.config/hypr/hypridle.conf;
  ".config/waybar/config.jsonc".source = ../../../waybar/.config/waybar/config.jsonc;
  ".config/waybar/style.css".source = ../../../waybar/.config/waybar/style.css;
  ".config/swaync/config.json".source = ../../../swaync/.config/swaync/config.json;
  ".config/swaync/style.css".source = ../../../swaync/.config/swaync/style.css;
  ".config/rofi/config.rasi".source = ../../../rofi/.config/rofi/config.rasi;
  ".config/hypr/wallpapers" = {
    source = ../../../hypr/.config/hypr/wallpapers;
    recursive = true; # Garante que copia subpastas, se existirem
  };
  ".config/MangoHud/MangoHud.conf".text = ''
    preset=3
    cpu_temp
    gpu_temp
    ram
    vram
    fps
    frametime
    # Atalho para ligar/desligar o HUD (Shift Direito + F12)
    toggle_hud=Shift_R+F12
    # Estilo visual
    round_corners=10
    background_alpha=0.4
    font_size=24
    text_color=ffffff
    position=top-left
'';
".config/gamemode.ini".text = ''
  [general]
  removerenice=1
  desiredgov=performance
  igpu_power_threshold=-1

  [custom]
  # Executa o script visual ao entrar no jogo
  start=sh /home/stardust/.config/hypr/scripts/gamemode.sh start
  
  # Executa o script visual ao sair do jogo
  end=sh /home/stardust/.config/hypr/scripts/gamemode.sh end
'';

".config/hypr/scripts/gamemode.sh" = {
  executable = true;
  text = ''
    #!/bin/bash
    
    # Função para Modo Jogo (Performance)
    enable_game_mode() {
        # 1. Matar Waybar e Wallpaper para poupar recursos
        pkill waybar || true
        pkill -STOP wall-manager || true
        
        # 2. Desligar Efeitos Visuais do Hyprland
        hyprctl --batch "\
            keyword animations:enabled 0;\
            keyword decoration:drop_shadow 0;\
            keyword decoration:blur:enabled 0;\
            keyword general:gaps_in 0;\
            keyword general:gaps_out 0;\
            keyword decoration:rounding 0"
            
        notify-send -u low -t 2000 "Game Mode" "⚡ ATIVADO: Foco Total"
    }

    # Função para Modo Desktop (Beleza)
    disable_game_mode() {
        # 1. Restaurar Hyprland (Lê a config original)
        hyprctl reload
        
        # 2. Restaurar Wallpaper e Waybar
        pkill -CONT wall-manager || true
        sleep 0.5
        waybar &
        
        notify-send -u low -t 2000 "Game Mode" "✨ DESATIVADO: Desktop Normal"
    }

    # Lógica de Controlo
    if [ "$1" == "start" ]; then
        enable_game_mode
    elif [ "$1" == "end" ]; then
        disable_game_mode
    else
        # Se não houver argumentos (Toggle manual via atalho)
        STATUS=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
        if [ "$STATUS" = 1 ]; then
            enable_game_mode
            # Truque: Se for manual, ativamos o gamemode em background
            gamemoderun sleep infinity > /dev/null 2>&1 &
            echo $! > /tmp/gamemode_manual.pid
        else
            disable_game_mode
            # Matar o gamemode manual
            if [ -f /tmp/gamemode_manual.pid ]; then
                kill $(cat /tmp/gamemode_manual.pid) 2>/dev/null
                rm /tmp/gamemode_manual.pid
            fi
        fi
    fi
  '';
};
".config/hypr/env.conf".text = ''
    # --- CURSOR (Estático, pois gostas do Bibata) ---
    env = XCURSOR_THEME,Bibata-Modern-Ice
    env = XCURSOR_SIZE,24

    # --- TEMAS (Dinâmico gerado pelo Nix) ---
    # O Nix preenche isto com "Nordic", "Tokyonight-Dark" ou "Gruvbox-Dark-B"
    env = GTK_THEME,${currentGtkTheme.name}
    
    # Força Qt a usar o estilo GTK2 (para ler o tema acima)
    env = QT_QPA_PLATFORMTHEME,gtk2
  '';

".config/hypr/scripts/vscode-theme.sh" = {
  executable = true;
  text = ''
    #!/bin/bash
    
    # Caminho do settings.json do VSCodium
    VSCODE_SETTINGS="$HOME/.config/VSCodium/User/settings.json"
    
    # Garante que o ficheiro existe
    if [ ! -f "$VSCODE_SETTINGS" ]; then
        mkdir -p "$(dirname "$VSCODE_SETTINGS")"
        echo "{}" > "$VSCODE_SETTINGS"
    fi

    update_theme() {
        local theme="$1"
        
        # Usa o 'sed' para substituir a linha do tema no JSON
        # Se a linha não existir, poderiamos usar 'jq', mas 'sed' é mais universal para replacement simples
        
        if grep -q "workbench.colorTheme" "$VSCODE_SETTINGS"; then
            # Se ja existe, substitui
            sed -i "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$theme\"/" "$VSCODE_SETTINGS"
        else
            # Se nao existe, adiciona antes da ultima chaveta
            sed -i "$ s/}/,\n  \"workbench.colorTheme\": \"$theme\"\n}/" "$VSCODE_SETTINGS"
        fi
    }

    case "$1" in
        "nord")
            update_theme "Nord"
            ;;
        "gruvbox")
            update_theme "Gruvbox Dark Hard"
            ;;
        "aizome")
            update_theme "Nightingale"
            ;;
        *)
            echo "Uso: $0 [nord|gruvbox]"
            ;;
    esac
  '';
};
};

home.activation = {
  restartServices = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Reiniciar Waybar (USR2 recarrega sem fechar)
    # Usamos o pkill do Nix para garantir que o comando existe
    ${pkgs.procps}/bin/pkill -USR2 waybar || /usr/bin/waybar &
    
    # Reiniciar SwayNC
    # 1. Verifica se está a correr usando o pgrep do Nix
    if ${pkgs.procps}/bin/pgrep -x "swaync" > /dev/null; then
       # 2. Usa o swaync-client com caminho absoluto do Arch
       /usr/bin/swaync-client -R && /usr/bin/swaync-client -rs
    else
       /usr/bin/swaync &
    fi
  '';
};

# ============================================================
  # ESTÉTICA DO SISTEMA (GTK & QT)
  # ============================================================

  # 1. Configuração GTK (Thunar, Pavucontrol, Firefox, etc)
  gtk = {
    enable = true;
    
    theme = {
      name = currentGtkTheme.name;
      package = currentGtkTheme.pkg;
    };

    iconTheme = {
      name = "Papirus-Dark"; # Vamos padronizar no Papirus que instalaste no Pacman
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # 2. Configuração Qt (Apps KDE, VLC, qBittorrent)
  qt = {
    enable = true;
    
    # Força apps Qt a usarem o tema GTK (Uniformidade total!)
    platformTheme.name = "gtk"; 
    style.name = "gtk2";
  };
  
  # Variáveis de ambiente para garantir que o tema pega
home.sessionVariables = {
  GTK_THEME = currentGtkTheme.name;
  QT_QPA_PLATFORMTHEME = "gtk2";
  # ADICIONA ESTA LINHA:
  XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
};

  # ============================================================
  # PROGRAMAS CONFIGURADOS
  # ============================================================
  home.packages = (with pkgs; [
    eza bat ripgrep fzf fd jq tldr fastfetch lazygit gh nerd-fonts.jetbrains-mono grim slurp swappy wl-clipboard cliphist gamemode protonup-qt gamescope mangohud ripgrep fd tmux zoxide yazi
    
    # Motores de Tema (Necessários para GTK funcionar bem)
    gtk-engine-murrine
    gnome-themes-extra
    
    nordic
    gruvbox-dark-gtk
    tokyonight-gtk-theme
    bibata-cursors
    papirus-icon-theme
  ]) ++ [ wall-manager power-menu ];
  
nixpkgs.config.allowUnfree = true;

  xdg.configFile."kitty/kitty.conf".force = true;
  fonts.fontconfig.enable = true;
  programs.kitty = {
    enable = true;
    package = pkgs.runCommand "dummy" {} "mkdir -p $out/bin";
    settings = {
      "linux_display_server" = "x11";
# --- FONTE ---
    "font_family"      = "JetBrainsMono Nerd Font";
    "bold_font"        = "auto";
    "italic_font"      = "auto";
    "bold_italic_font" = "auto";
    "font_size"        = "12.0";

    # --- JANELA & VISUAL ---
    "background_opacity" = "0.85";
    "window_padding_width" = 10;
    "hide_window_decorations" = "yes";
    "confirm_os_window_close" = 0;

    # --- CURSOR ---
    "cursor_shape"     = "beam";
    "cursor_blink_interval" = "0.5";
    # --- MOUSE & URLS ---
    "url_color"        = "#${colors.accent1}";
    "url_style"        = "curly";
    "detect_urls"      = "yes";
    "copy_on_select"   = "yes";
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
  initContent = ''
    fastfetch
    set-theme() {
        local TEMA=$1
        if [[ "$TEMA" != "nord" && "$TEMA" != "aizome" && "$TEMA" != "gruvbox" ]]; then
          echo "❌ Tema inválido! Usa: nord, aizome ou gruvbox"
          return 1
        fi
        
        # Grava na cache (força a criação da pasta se não existir)
        mkdir -p ~/.cache
        echo "$TEMA" > "$HOME/.cache/current_theme"
        
        echo "🎨 Cache atualizada para: $(cat ~/.cache/current_theme)"
        # 3. Executar o hms (Repara que agora não precisamos de 'git add' porque o código não mudou)
        if home-manager switch -b backup --impure --flake ~/arch-install-script/nix/.config/home-manager#stardust; then
            # 4. Sincronizar Wallpaper
            ~/.nix-profile/bin/wall-manager switch "$1"
            echo "🚀 Sistema atualizado para $1!"
        else
            echo "❌ Erro ao aplicar o Nix."
            return 1
        fi
      }
  '';
	shellAliases ={
		ll="eza -l -g --icons";
		ls="eza --icons";
		cat="bat";
		update="sudo pacman -Syu";
    # --- NIX & HOME MANAGER ALIASES ---
    hms = "home-manager switch -b backup --impure --flake ~/arch-install-script/nix/.config/home-manager#stardust";
    hmu="nix flake update ~/arch-install-script/nix/.config/home-manager && hms";
    nclean="nix-collect-garbage -d";
    hme="cd ~/arch-install-script/nix/.config/home-manager && $EDITOR flake.nix";
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

  # ==========================================
  # FERRAMENTAS DE TERMINAL (INTEGRADAS)
  # ==========================================

   # 1. Zoxide: O 'cd' inteligente
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      # Substitui o comando 'cd' normal pelo zoxide (opcional, mas recomendado)
      # Se preferires manter o cd normal, remove esta linha e usa 'z' para navegar
      options = ["--cmd cd"]; 
    };

    # 2. Yazi: O Gestor de Ficheiros Visual
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      # Configurações de shell wrapper (cria o comando 'y' que muda o diretório ao sair)
      shellWrapperName = "y";
    };

    # 3. Tmux: O Multiplexer
    programs.tmux = {
      enable = true;
      mouse = true;       # Permite usar o rato para redimensionar painéis (Essencial!)
      baseIndex = 1;      # Começa a contar janelas no 1 em vez do 0 (mais lógico)
      prefix = "C-a";     # Muda o atalho mestre de Ctrl+B para Ctrl+A (mais fácil de carregar)
      keyMode = "vi";     # Usa teclas do Vim (hjkl) para scroll e seleção
      
      # Plugins essenciais para ficar bonito e útil
      plugins = with pkgs; [
        tmuxPlugins.cpu
        tmuxPlugins.yank
        tmuxPlugins.resurrect # Salva a sessão para não perderes nada se o PC reiniciar
      ];
      
      extraConfig = ''
        # Abrir novos painéis no diretório atual (e não na home)
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
      '';
    };

services.flatpak = {
    enable = true;
    uninstallUnmanaged = true; # O "Gari" do sistema: apaga o lixo que não está no código
    
    remotes = lib.mkOptionDefault [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];

    packages = [
      # "com.spotify.Client"
      # "com.discordapp.Discord"
      # Adiciona aqui as tuas apps pesadas
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
  #  /etc/profiles/per-user/stardust/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
