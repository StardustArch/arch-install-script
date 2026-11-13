{ config, pkgs, lib, username, ... }:

let
  home = config.home.homeDirectory;

  # ============================================================
  # CENTRAL DE TEMAS
  # ============================================================
  # Lê o tema da cache; se não existir, usa "aizome" (evita falhar a avaliação)
  themeFile = "${home}/.cache/current_theme";
  rawTheme = if builtins.pathExists themeFile then builtins.readFile themeFile else "aizome";
  selectedTheme = lib.removeSuffix "\n" rawTheme;

  # Nota: GTK/Qt/ícones/cursor são agora geridos pelo Noctalia;
  # não há pacotes GTK a instalar aqui via Home Manager.

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
  colors = themes.${selectedTheme};

  # ============================================================
  # SCRIPTS
  # ============================================================
  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    shutdown="⏻ Desligar"
    reboot="⟳ Reiniciar"
    lock="🔒 Bloquear"
    logout="⇠ Sair"

    selected=$(echo -e "$lock\n$logout\n$reboot\n$shutdown" | rofi -dmenu -p "Energia" -theme-str 'window {width: 300px;}')

    case $selected in
      "$shutdown") systemctl poweroff ;;
      "$reboot") systemctl reboot ;;
      "$lock") pidof hyprlock || hyprlock ;;
      "$logout") hyprctl dispatch exit ;;
    esac
  '';

in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11"; # Não alterar sem ler as release notes.

  # ============================================================
  # FICHEIROS (cores geradas + dotfiles do repo)
  # ============================================================
  home.file = {
    # --- Cores geradas a partir do tema activo ---
    ".config/hypr/colors.conf".text = ''
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

    ".config/waybar/colors.css".text = ''
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

    ".config/rofi/colors.rasi".text = ''
      * {
        bg: #${colors.bg0}f2;
        bg-alt: #${colors.bg1};
        bg-sel: #${colors.bg2};
        fg: #${colors.fg0};
        accent: #${colors.accent1};
        muted: #${colors.bg3};
      }
    '';

    # --- Dotfiles do repo (Hyprland 0.55+ Lua — estrutura CachyOS espelhada) ---
    ".config/hypr/hyprland.lua".source = ../../../hypr/.config/hypr/hyprland.lua;
    ".config/hypr/xdph.conf".source = ../../../hypr/.config/hypr/xdph.conf;
    ".config/hypr/config/variables.lua".source = ../../../hypr/.config/hypr/config/variables.lua;
    ".config/hypr/config/colors.lua".source = ../../../hypr/.config/hypr/config/colors.lua;
    ".config/hypr/config/environment.lua".source = ../../../hypr/.config/hypr/config/environment.lua;
    ".config/hypr/config/monitors.lua".source = ../../../hypr/.config/hypr/config/monitors.lua;
    ".config/hypr/config/inputs.lua".source = ../../../hypr/.config/hypr/config/inputs.lua;
    ".config/hypr/config/decorations.lua".source = ../../../hypr/.config/hypr/config/decorations.lua;
    ".config/hypr/config/animations.lua".source = ../../../hypr/.config/hypr/config/animations.lua;
    ".config/hypr/config/misc.lua".source = ../../../hypr/.config/hypr/config/misc.lua;
    ".config/hypr/config/workspaces.lua".source = ../../../hypr/.config/hypr/config/workspaces.lua;
    ".config/hypr/config/windowrules.lua".source = ../../../hypr/.config/hypr/config/windowrules.lua;
    ".config/hypr/config/autostart.lua".source = ../../../hypr/.config/hypr/config/autostart.lua;
    ".config/hypr/config/binds.lua".source = ../../../hypr/.config/hypr/config/binds.lua;
    ".config/kitty/kitty.conf".source = ../../../kitty/.config/kitty/kitty.conf;

    # --- Dotfiles do repo (legacy .conf — mantidos temporariamente, DESLIGADOS após migração) ---
    # ".config/hypr/env.conf".text = ''  -- legacy: env vars agora em config/environment.lua via hl.env()
    #   env = XCURSOR_THEME,Bibata-Modern-Ice
    #   env = XCURSOR_SIZE,24
    #   env = GTK_THEME,<gerido pelo Noctalia>
    # '';
    # ".config/hypr/hyprland.conf".source = ../../../hypr/.config/hypr/hyprland.conf;  -- legacy, removido após migração
    # ".config/hypr/lua/theme.lua".source = ../../../hypr/.config/hypr/lua/theme.lua;   -- legacy, substituído por config/colors.lua
    # ".config/hypr/lua/general.lua".source = ../../../hypr/.config/hypr/lua/general.lua; -- legacy, substituído por config/decorations.lua + misc.lua
    # ".config/hypr/lua/keybinds.lua".source = ../../../hypr/.config/hypr/lua/keybinds.lua; -- legacy, substituído por config/binds.lua
    # ".config/hypr/lua/autostart.lua".source = ../../../hypr/.config/hypr/lua/autostart.lua; -- legacy, substituído por config/autostart.lua
    # ".config/hypr/lua/rules.lua".source = ../../../hypr/.config/hypr/lua/rules.lua; -- legacy, substituído por config/windowrules.lua
    ".config/hypr/hyprtoolkit.conf".source = ../../../hypr/.config/hypr/hyprtoolkit.conf;
    # ".config/hypr/hyprlock.conf".source = ../../../hypr/.config/hypr/hyprlock.conf;  -- legacy: substituído por Noctalia lockscreen
    # ".config/hypr/hypridle.conf".source = ../../../hypr/.config/hypr/hypridle.conf;   -- legacy: substituído por Noctalia idle
    # ".config/waybar/config.jsonc".source = ../../../waybar/.config/waybar/config.jsonc; -- legacy: substituído por Noctalia bar
    # ".config/waybar/style.css".source = ../../../waybar/.config/waybar/style.css;      -- legacy
    # ".config/swaync/config.json".source = ../../../swaync/.config/swaync/config.json; -- legacy: substituído por Noctalia notifications
    # ".config/swaync/style.css".source = ../../../swaync/.config/swaync/style.css;      -- legacy
    # ".config/rofi/config.rasi".source = ../../../rofi/.config/rofi/config.rasi;        -- legacy: substituído por Noctalia launcher
    ".config/noctalia/config.toml".source = ../../../noctalia/.config/noctalia/config.toml;
    ".config/hypr/wallpapers" = {
      source = ../../../hypr/.config/hypr/wallpapers;
      recursive = true;
    };

    ".config/hypr/scripts/vscode-theme.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        VSCODE_SETTINGS="${home}/.config/VSCodium/User/settings.json"

        if [ ! -f "$VSCODE_SETTINGS" ]; then
            mkdir -p "$(dirname "$VSCODE_SETTINGS")"
            echo "{}" > "$VSCODE_SETTINGS"
        fi

        update_theme() {
            local theme="$1"
            if grep -q "workbench.colorTheme" "$VSCODE_SETTINGS"; then
                sed -i "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$theme\"/" "$VSCODE_SETTINGS"
            else
                sed -i "$ s/}/,\n  \"workbench.colorTheme\": \"$theme\"\n}/" "$VSCODE_SETTINGS"
            fi
        }

        case "$1" in
            "nord")    update_theme "Nord" ;;
            "gruvbox") update_theme "Gruvbox Dark Soft" ;;
            "aizome")  update_theme "Nightingale" ;;
            *)         echo "Uso: $0 [nord|gruvbox|aizome]" ;;
        esac
      '';
    };
  };

  home.activation.restartServices = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.procps}/bin/pkill -USR2 waybar || /usr/bin/waybar &

    if ${pkgs.procps}/bin/pgrep -x "swaync" > /dev/null; then
       /usr/bin/swaync-client -R && /usr/bin/swaync-client -rs
    else
       /usr/bin/swaync &
    fi
  '';

  # ============================================================
  # GTK/Qt geridos pelo Noctalia (não configurar aqui via Home Manager)
  # ============================================================

  home.sessionVariables = {
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$HOME/.local/share:/usr/share:$XDG_DATA_DIRS";
  };

  # ============================================================
  # PACOTES (só CLI e o essencial; fonte Nerd vem do pacman)
  # ============================================================
  home.packages = (with pkgs; [
    eza bat ripgrep fzf fd jq tldr fastfetch lazygit gh
    grim slurp swappy wl-clipboard dconf
    glib gsettings-desktop-schemas
  ]) ++ [ power-menu ];

  dconf.enable = true;
  nixpkgs.config.allowUnfree = true;
  fonts.fontconfig.enable = true;

  # ============================================================
  # PROGRAMAS
  # ============================================================
  programs.git = {
    enable = true;
    settings.user = {
      name = "StardustArch";
      email = "paulojoaocandrinho4@gmail.com";
    };
  };

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

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
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

  programs.home-manager.enable = true;
}
