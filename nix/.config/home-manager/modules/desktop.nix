{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # ============================================================
  # CENTRAL DE TEMAS
  # ============================================================
  # Lê o tema da cache; se não existir, usa "aizome" (evita falhar a avaliação)
  themeFile = "${home}/.cache/current_theme";
  rawTheme = if builtins.pathExists themeFile then builtins.readFile themeFile else "aizome";
  selectedTheme = lib.removeSuffix "\n" rawTheme;

  # Noctalia gera as cores (noctalia.css). Esta paleta só alimenta
  # .config/hypr/colors.conf, consumido por hyprtoolkit.conf.
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
in
{
  home.file = {
    # --- Cores geradas a partir do tema activo (consumido por hyprtoolkit.conf) ---
    ".config/hypr/colors.conf".text = ''
      $bg0 = rgba(${colors.bg0}ff)
      $bg1 = rgba(${colors.bg1}ff)
      $bg3 = rgba(${colors.bg3}ff)
      $fg0 = rgba(${colors.fg0}ff)
      $fg2 = rgba(${colors.fg2}ff)
      $accent1 = rgba(${colors.accent1}ff)
      $accent2 = rgba(${colors.accent2}ff)
    '';

    # --- Variáveis de ambiente exportadas pelo UWSM antes de iniciar Hyprland ---
    # (Conforme sugerido em hypr/.config/hypr/config/environment.lua:
    #  "if you use UWSM, define your variables in ~/.config/uwsm/env")
    ".config/uwsm/env".text = ''
      # Tema e tamanho do cursor — devem bater com /usr/share/icons/<tema>
      XCURSOR_THEME=Bibata-Modern-Ice
      XCURSOR_SIZE=24
    '';

    # --- Dotfiles do repo (Hyprland 0.55+ Lua — estrutura CachyOS espelhada) ---
    ".config/hypr/hyprland.lua".source = ../../../../hypr/.config/hypr/hyprland.lua;
    ".config/hypr/xdph.conf".source = ../../../../hypr/.config/hypr/xdph.conf;
    # hypr/.config/hypr/config contém apenas ficheiros .lua (12, verificados
    # em Fase 0) → um único source recursivo em vez de 12 entradas
    ".config/hypr/config" = {
      source = ../../../../hypr/.config/hypr/config;
      recursive = true;
    };
    ".config/hypr/hyprtoolkit.conf".source = ../../../../hypr/.config/hypr/hyprtoolkit.conf;
    ".config/hypr/wallpapers" = {
      source = ../../../../hypr/.config/hypr/wallpapers;
      recursive = true;
    };
    ".config/kitty/kitty.conf".source = ../../../../kitty/.config/kitty/kitty.conf;

    ".config/noctalia/config.toml".source = ../../../../noctalia/.config/noctalia/config.toml;

    # --- Scripts ---
    # vscode-theme.sh: mantido inline pois não é chamado por nenhum bind
    # ou autostart activo (candidato a remoção — ver relatório).
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
}
