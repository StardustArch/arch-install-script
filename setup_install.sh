#!/bin/bash

# ==========================================
# CONFIGURAÇÃO E VARIÁVEIS
# ==========================================
set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOTFILES_DIR="$HOME/dotfiles"
REPO_DIR="$HOME/arch-install-script"
NIX_CONF_DIR="$HOME/arch-install-script/nix/.config/home-manager"

# Etapa a executar (por omissão executa tudo)
STAGE="${1:-all}"

log() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
err()  { echo -e "${RED}[X] $1${NC}"; }

trap 'err "Erro na linha $LINENO. Verifique a saída acima."' ERR

# ==========================================
# AJUDA / USO
# ==========================================
usage() {
  cat <<EOF
Uso: $0 [--stage=<etapa> | <etapa>]

Executa o setup 'ARCH ETERNO' de forma modular. Sem argumentos executa todas as etapas.

Etapas disponíveis:
  mirrors   1 - Otimização de mirrors (reflector)
  yay       2 - Verificação/instalação do AUR helper (yay)
  packages  3 - Atualização e instalação de pacotes base (pacman + yay)
  plymouth  4 - Configuração do Plymouth (hook mkinitcpio, GRUB, tema, initramfs)
  greetd    5 - Configuração do Display Manager (Greetd + tuigreet)
  cache     6 - Inicialização de cache e ficheiro de tema
  nix       7 - Instalação do Nix, flakes, Home Manager e dotfiles
  vscode    8 - Configuração do VS Code / VSCodium e extensões
  zsh       9 - Definir Zsh do Nix como shell padrão
  themes   10 - Compatibilidade de temas (Nix -> Arch bridge) e serviços
  qt       11 - Tema Qt/KDE (qt6ct-kde, esquema 'noctalia' para o Dolphin)

Exemplos:
  $0                      # executa tudo (predefinido)
  $0 --stage=plymouth     # executa apenas a etapa do Plymouth
  $0 plymouth             # idem (forma curta)
  $0 --stage=nix          # executa apenas Nix + Home Manager

Notas:
  - Algumas etapas têm dependências de etapas anteriores (ver validações).
  - Use --stage=all para forçar execução completa.
EOF
}

# ==========================================
# PARSING DE ARGUMENTOS
# ==========================================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage=*)
      STAGE="${1#*=}"
      shift
      ;;
    --stage)
      STAGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      # Forma curta: $0 plymouth
      STAGE="$1"
      shift
      ;;
  esac
done

# Normaliza STAGE para minúsculas
STAGE="$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')"

# ==========================================
# CONTROLO DE EXECUÇÃO DE ETAPA
# ==========================================
# Retorna 0 (verdadeiro) se a etapa deve ser executada, 1 caso contrário.
should_run() {
  local target="$1"
  if [[ "$STAGE" == "all" || "$STAGE" == "$target" ]]; then
    return 0
  fi
  return 1
}

# ==========================================
# VALIDAÇÃO DE PRÉ-REQUISITOS POR ETAPA
# Garante que dependências de etapas anteriores estão presentes
# antes de executar uma etapa isoladamente.
# ==========================================
check_prerequisites() {
  case "$STAGE" in
    plymouth)
      log "Validando pré-requisitos da etapa 'plymouth'..."
      if ! command -v plymouth-set-default-theme &>/dev/null; then
        err "Plymouth não está instalado no sistema."
        err "Execute primeiro a etapa de pacotes: $0 --stage=packages"
        exit 1
      fi
      if ! command -v grub-mkconfig &>/dev/null && [ -f /etc/default/grub ]; then
        warn "grub-mkconfig não encontrado; a configuração do GRUB pode ser ignorada."
      fi
      ;;
    greetd)
      log "Validando pré-requisitos da etapa 'greetd'..."
      if ! command -v tuigreet &>/dev/null; then
        err "tuigreet não está instalado no sistema."
        err "Execute primeiro a etapa de pacotes: $0 --stage=packages"
        exit 1
      fi
      ;;
    cache)
      log "Validando pré-requisitos da etapa 'cache'..."
      if ! command -v tuigreet &>/dev/null; then
        warn "tuigreet não encontrado (etapa de pacotes pode não ter runido)."
      fi
      ;;
    nix)
      log "Validando pré-requisitos da etapa 'nix'..."
      if ! command -v curl &>/dev/null; then
        err "curl não está instalado (necessário para instalar o Nix)."
        exit 1
      fi
      ;;
    vscode)
      log "Validando pré-requisitos da etapa 'vscode'..."
      if ! command -v yay &>/dev/null; then
        err "yay não está instalado (necessário para instalar o VSCodium)."
        err "Execute primeiro: $0 --stage=yay"
        exit 1
      fi
      ;;
    zsh)
      log "Validando pré-requisitos da etapa 'zsh'..."
      if ! command -v nix &>/dev/null; then
        err "Nix não está instalado (necessário para o Zsh do Nix)."
        err "Execute primeiro: $0 --stage=nix"
        exit 1
      fi
      ;;
    themes)
      log "Validando pré-requisitos da etapa 'themes'..."
      if ! command -v nix &>/dev/null; then
        err "Nix não está instalado (necessário para a ponte de temas)."
        err "Execute primeiro: $0 --stage=nix"
        exit 1
      fi
      if ! command -v glib-compile-schemas &>/dev/null; then
        err "glib-compile-schemas não encontrado."
        err "Execute primeiro: $0 --stage=packages"
        exit 1
      fi
      ;;
    packages)
      log "Validando pré-requisitos da etapa 'packages'..."
      if ! command -v yay &>/dev/null; then
        err "yay não está instalado (necessário para pacotes AUR)."
        err "Execute primeiro: $0 --stage=yay"
        exit 1
      fi
      ;;
    yay)
      # Não tem pré-requisitos além do próprio sistema
      ;;
    mirrors)
      # Não tem pré-requisitos
      ;;
    all)
      ;;
    *)
      err "Etapa desconhecida: $STAGE"
      usage
      exit 1
      ;;
  esac
}

# ==========================================
# FUNÇÕES POR ETAPA
# ==========================================

stage_mirrors() {
  # ==========================================
  # 1. OTIMIZAÇÃO DE MIRRORS
  # ==========================================
  log "Etapa 1/10 - Otimização de mirrors..."
  if command -v reflector &> /dev/null; then
    if [ -n "$(find /etc/pacman.d/mirrorlist -mtime -1 2>/dev/null)" ]; then
      warn "Mirrors atualizados recentemente. Pulando."
    else
      log "Otimizando mirrors..."
      sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
      sudo reflector --country 'South Africa,Brazil,Portugal' --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    fi
  else
    log "Instalando Reflector..."
    sudo pacman -Sy --noconfirm --needed reflector
  fi
}

stage_yay() {
  # ==========================================
  # 2. VERIFICAÇÃO DO YAY (AUR HELPER)
  # ==========================================
  log "Etapa 2/10 - Verificação do AUR Helper (yay)..."
  if ! command -v yay &> /dev/null; then
    warn "O 'yay' não foi encontrado no sistema."
    echo -e "${YELLOW}[?] O 'yay' é necessário para instalar temas de ícones, cursores e outros pacotes do AUR.${NC}"
    read -p "Deseja instalar o 'yay' agora? [S/n]: " YAY_INSTALL
    YAY_INSTALL=${YAY_INSTALL:-S}

    if [[ "$YAY_INSTALL" =~ ^[Ss] ]]; then
      log "Instalando dependências de build e clonando o yay..."
      sudo pacman -S --needed --noconfirm git base-devel

      TEMP_YAY=$(mktemp -d)
      git clone https://aur.archlinux.org/yay.git "$TEMP_YAY"
      cd "$TEMP_YAY"
      makepkg -si --noconfirm
      cd - > /dev/null
      rm -rf "$TEMP_YAY"
      log "Yay instalado com sucesso."
    else
      err "O 'yay' é obrigatório para este setup (necessário para Bibata, Papirus, etc). Abortando."
      exit 1
    fi
  else
    log "Yay já está presente."
  fi
}

stage_packages() {
  # ==========================================
  # 3. ATUALIZAÇÃO E PACOTES BASE
  # ==========================================
  log "Etapa 3/10 - Atualização e pacotes base..."
  log "Sincronizando sistema..."
  sudo pacman -Syu --noconfirm

  log "Instalando pacotes base e interface..."

  # Lista unificada (Pacman + AUR via yay)
  PKGS=(
      hyprland hyprpaper swaybg xorg-xwayland
      kitty hyprtoolkit
      pipewire pipewire-pulse wireplumber polkit-gnome
      dolphin ttf-jetbrains-mono-nerd flatpak
      xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
      xdg-desktop-portal
      brightnessctl
      greetd greetd-tuigreet
      noctalia uwsm adw-gtk-theme qt6ct-kde hyprpicker kde-cli-tools
      # Temas de cursor e ícones (AUR) — necessários para o cursor não desaparecer em bare metal
      bibata-cursor-theme papirus-icon-theme
      podman distrobox podman-compose btop plymouth
  )

  # qt6ct-kde substitui o qt6ct e os dois conflitam: com --noconfirm o pacman
  # responderia "não" ao conflito, por isso removemos o qt6ct antes.
  if pacman -Q qt6ct &>/dev/null && ! pacman -Q qt6ct-kde &>/dev/null; then
    log "Removendo 'qt6ct' (substituído por 'qt6ct-kde')..."
    sudo pacman -Rdd --noconfirm qt6ct
  fi

  # Usa o yay para instalar tudo (ele lida com pacotes oficiais e AUR simultaneamente)
  yay -S --noconfirm --needed "${PKGS[@]}"

  # Habilitar Podman Socket
  if ! systemctl --user is-active --quiet podman.socket; then
    log "Habilitando Podman Socket..."
    systemctl --user enable --now podman.socket
  fi
}

stage_plymouth() {
  # ==========================================
  # 4. CONFIGURAÇÃO DO PLYMOUTH
  # ==========================================
  log "Etapa 4/10 - Configuração do Plymouth (Animação de Boot)..."

  local NEED_REBUILD=0
  local MKINIT_CONF="/etc/mkinitcpio.conf"
  local GRUB_DEFAULT_FILE="/etc/default/grub"

  # 4.1 Adicionar Hook ao mkinitcpio (só na linha HOOKS=, ignora comentários)
  if ! grep -E '^HOOKS=' "$MKINIT_CONF" | grep -qw "plymouth"; then
    log "Adicionando hook 'plymouth' ao mkinitcpio..."
    if grep -E '^HOOKS=' "$MKINIT_CONF" | grep -qw "systemd"; then
      # Initramfs baseado em systemd: plymouth vai logo após 'systemd'
      sudo sed -i -E '/^HOOKS=/ s/\bsystemd\b/systemd plymouth/' "$MKINIT_CONF"
    else
      # Initramfs baseado em busybox: plymouth vai logo após 'udev'
      sudo sed -i -E '/^HOOKS=/ s/\budev\b/udev plymouth/' "$MKINIT_CONF"
    fi
    NEED_REBUILD=1
  else
    log "Hook do Plymouth já configurado."
  fi

  # 4.2 Configurar GRUB para Boot Silencioso (quiet splash)
  if [ -f "$GRUB_DEFAULT_FILE" ]; then
    local GRUB_CHANGED=0
    local param
    # Cada parâmetro é verificado em separado (idempotente, não duplica)
    for param in quiet splash; do
      if ! grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_DEFAULT_FILE" | grep -qw "$param"; then
        log "Adicionando '$param' ao GRUB..."
        # Acrescenta no fim da linha, antes da aspa final
        sudo sed -i -E "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/([\"'])\$/ $param\1/" "$GRUB_DEFAULT_FILE"
        GRUB_CHANGED=1
      fi
    done

    if [ "$GRUB_CHANGED" -eq 1 ]; then
      # Caminho onde o GRUB realmente lê o grub.cfg (Arch: /boot/grub)
      local GRUB_CFG="/boot/grub/grub.cfg"
      [ -d /boot/grub ] || GRUB_CFG="/boot/efi/grub/grub.cfg"
      log "Atualizando configuração do GRUB ($GRUB_CFG)..."
      sudo grub-mkconfig -o "$GRUB_CFG"
    else
      log "Parâmetros 'quiet splash' já presentes no GRUB."
    fi
  else
    warn "GRUB não encontrado (Systemd-boot?). Adicione 'quiet splash' manualmente ao seu bootloader."
  fi

  # 4.3 Definir Tema e Gerar Initramfs
  local TARGET_THEME="spinner"
  local CURRENT_THEME
  CURRENT_THEME=$(plymouth-set-default-theme)

  if [ "$CURRENT_THEME" != "$TARGET_THEME" ]; then
    log "Tema do Plymouth diferente de $TARGET_THEME. Atualizando..."
    # O flag -R já reconstrói o initramfs (inclui o hook novo, se houver)
    sudo plymouth-set-default-theme -R "$TARGET_THEME"
  elif [ "$NEED_REBUILD" -eq 1 ]; then
    log "Tema já é $TARGET_THEME, mas o mkinitcpio mudou. Reconstruindo initramfs..."
    sudo mkinitcpio -P
  else
    log "Plymouth já está configurado como $TARGET_THEME. Ignorando reconstrução do boot."
  fi
}

stage_greetd() {
  # ==========================================
  # 5. CONFIGURAÇÃO DO DISPLAY MANAGER (GREETD + TUI GREET)
  # ==========================================
  log "Etapa 5/10 - Configuração do Display Manager (Greetd + tuigreet)..."

  # Instalar utilizador do greetd se não existir
  if ! id "greeter" &>/dev/null; then
    sudo useradd -r -s /bin/false greeter
  fi

  # Criar configuração do greetd
  sudo mkdir -p /etc/greetd
  sudo tee /etc/greetd/config.toml > /dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --time-format '%H:%M | %a %h %d' --remember --remember-user-session --cmd 'uwsm start hyprland-uwsm.desktop'"
user = "greeter"
EOF
}

stage_cache() {
  # ====================================================
  # 6. INICIALIZAÇÃO DE CACHE E TEMA
  # ====================================================
  log "Etapa 6/10 - Inicialização de cache e tema..."

  # Verifica se o diretório de cache existe
  if [ ! -d "$HOME/.cache" ]; then
    log "Criando diretório de cache em ~/.cache..."
    mkdir -p "$HOME/.cache"
  fi

  # Verifica se o ficheiro de controlo de tema existe
  if [ ! -f "$HOME/.cache/current_theme" ]; then
    log "Inicializando ficheiro de persistência de tema..."
    touch "$HOME/.cache/current_theme"
    echo "aizome" > "$HOME/.cache/current_theme"
  else
    log "Ficheiro de tema já existe. Ignorando inicialização."
  fi

  # Verifica se o ficheiro de controlo de tema existe
  if [ ! -s "$HOME/.cache/current_theme" ]; then
    log "Inicializando tema padrão (aizome)..."
    # O uso de echo garante que o ficheiro não fica vazio
    echo "aizome" > "$HOME/.cache/current_theme"
  else
    log "Ficheiro de tema detetado: $(cat ~/.cache/current_theme)"
  fi
}

stage_nix() {
  # ==========================================
  # 7. INSTALAÇÃO DO NIX & ATIVAÇÃO DE FLAKES
  # ==========================================
  log "Etapa 7/10 - Instalação do Nix & ativação de Flakes..."

  # 1. Tenta carregar o Nix caso ele já exista mas não esteja no PATH
  for profile in "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" "$HOME/.nix-profile/etc/profile.d/nix.sh" "/etc/profile.d/nix.sh"; do
    if [ -e "$profile" ]; then
      log "Nix detectado no disco. Carregando ambiente..."
      . "$profile"
    fi
  done

  # 2. Agora sim, verifica se o comando 'nix' está disponível
  if ! command -v nix &> /dev/null; then
    log "Nix não encontrado. Instalando (via Determinate Systems)..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

    # Carrega imediatamente após instalar
    [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    log "Nix já está instalado e ativo. Ignorando instalação."
  fi

  # 3. Habilitar suporte a Flakes (apenas se necessário)
  mkdir -p ~/.config/nix
  if ! grep -q "flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    log "Habilitando suporte a Flakes..."
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  fi

  # --- 3. BOOTSTRAP DOS DOTFILES ---
  log "Preparando Dotfiles..."

  # ==========================================
  # GESTÃO DE GIT PARA FLAKES
  # ==========================================
  # Define o caminho exato onde estão os teus ficheiros Nix
  NIX_CONF_DIR="$HOME/arch-install-script/nix/.config/home-manager"
  REPO_DIR="$HOME/arch-install-script"

  if [ -d "$REPO_DIR/.git" ]; then
    log "Garantindo que os ficheiros em $NIX_CONF_DIR estão rastreados pelo Git..."

    # Entramos na raiz do repositório para o git add funcionar corretamente
    cd "$REPO_DIR"

    # Adicionamos os ficheiros pelo caminho relativo à raiz do repo
    git add nix/.config/home-manager/flake.nix nix/.config/home-manager/home.nix 2>/dev/null || true

    log "Ficheiros rastreados. O Nix agora consegue vê-los."
  fi

  # ====================================================
  # APLICAÇÃO ÚNICA E ROBUSTA DO HOME MANAGER
  # ====================================================
  log "Aplicando configuração do Home Manager..."

  export NIXPKGS_ALLOW_UNFREE=1
  export XDG_DATA_DIRS="$HOME/.nix-profile/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"

  # Utilizador detetado dinamicamente em runtime
  CURRENT_USER="$(whoami)"

  # Escolhe o comando home-manager: usa o instalado localmente se disponível,
  # senão executa diretamente do GitHub via nix run (bootstrapping)
  if command -v home-manager &> /dev/null; then
    HM_CMD="home-manager"
  else
    HM_CMD="nix run github:nix-community/home-manager/release-24.11 --"
  fi

  log "Aplicando Home Manager para o utilizador '$CURRENT_USER'..."

  # O dbus-run-session resolve o erro 'ServiceUnknown' em sessões sem D-Bus
  if command -v dbus-run-session &> /dev/null; then
    dbus-run-session -- $HM_CMD switch -b backup --impure --flake "$NIX_CONF_DIR#$CURRENT_USER"
  else
    $HM_CMD switch -b backup --impure --flake "$NIX_CONF_DIR#$CURRENT_USER"
  fi
}

stage_vscode() {
  # ==========================================
  # 8. CONFIGURAÇÃO DO VS CODE (AUTOMATIZADA)
  # ==========================================
  log "Etapa 8/10 - Instalação e Configuração do VS Code..."

  # 1. Instalar o binário do Arch (Versão OSS oficial)
  # Nota: Usamos 'code' do repo oficial. Se preferires mesmo o VSCodium, usa 'yay -S vscodium-bin'
  if ! command -v codium &> /dev/null; then
    yay -S --noconfirm --needed vscodium-bin
  fi

  # 2. Lista de Extensões (IDs do Marketplace)
  # Aqui traduzimos do Nix para o nome real na loja
  EXTENSIONS=(
      # --- Estética ---
      "PKief.material-icon-theme"
      "jdinhlife.gruvbox"
      "arcticicestudio.nord-visual-studio-code"
      # As que o Nix não encontrava:
      "bfrangi.vscode-nightingale-theme"             # Essencial para o tema Aizome
      "arcticicestudio.nord-visual-studio-code"
      # --- Stack Web (Svelte, Vue) ---
      "svelte.svelte-vscode"
      "Vue.volar"
      "dbaeumer.vscode-eslint"
      "esbenp.prettier-vscode"
      "bradlc.vscode-tailwindcss"

      # --- Python (Agora instala sem pedir licença!) ---
      "ms-python.python"
      "charliermarsh.ruff"

      # --- Utilitários ---
      "eamodio.gitlens"
      "EditorConfig.EditorConfig"

      # --- Opcional: Database ---
      # "mtxr.sqltools"
      "cweijan.vscode-database-client2"
  )

  log "Instalando extensões do VS Code..."
  for ext in "${EXTENSIONS[@]}"; do
    # --force garante que atualiza se já existir
    codium --install-extension "$ext" --force || warn "Falha ao instalar $ext (pode já estar instalada ou sem internet)"
  done

  # 3. Criar settings.json base (Se não existir)
  # Isto é CRÍTICO para o teu script de temas não falhar na primeira execução
  VSCODE_DIR="$HOME/.config/VSCodium/User" # Caminho do 'code' no Arch
  # Se usares vscodium, o caminho é "$HOME/.config/VSCodium/User"

  mkdir -p "$VSCODE_DIR"
  SETTINGS_FILE="$VSCODE_DIR/settings.json"

  if [ ! -f "$SETTINGS_FILE" ]; then
    log "Criando settings.json padrão..."
    cat <<EOF > "$SETTINGS_FILE"
{
    "workbench.colorTheme": "Nightingale",
    "workbench.iconTheme": "material-icon-theme",
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'monospace'",
    "editor.fontLigatures": true,
    "editor.fontSize": 14,
    "window.menuBarVisibility": "toggle",
    "files.autoSave": "afterDelay"
}
EOF
  else
    log "settings.json já existe. Mantendo configuração atual."
  fi
}

stage_zsh() {
  # ====================================================
  # 9. DEFINIR ZSH DO NIX COMO DEFAULT
  # ====================================================
  log "Etapa 9/10 - Definir Zsh do Nix como shell padrão..."

  echo "Setting Zsh as the default shell..."

  # 1. Localiza o binário do Zsh instalado pelo Nix
  NIX_ZSH_PATH=$(which zsh)

  # 2. Adiciona o caminho ao /etc/shells se não estiver lá (necessário para o chsh aceitar)
  if ! grep -q "$NIX_ZSH_PATH" /etc/shells; then
    echo "Adding Nix Zsh to /etc/shells..."
    echo "$NIX_ZSH_PATH" | sudo tee -a /etc/shells
  fi

  # 3. Altera o shell do utilizador stardust
  # Usamos sudo chsh para evitar o prompt de password e forçar a alteração
  sudo chsh -s "$NIX_ZSH_PATH" $(whoami)

  echo "Shell changed to Zsh! (You might need to relog to see the effect)"
}

stage_themes() {
  # ====================================================
  # 10. COMPATIBILIDADE DE TEMAS (NIX -> ARCH BRIDGE)
  # ====================================================
  log "Etapa 10/10 - Compatibilidade de temas (Nix -> Arch Bridge)..."

  log "Criando pontes de ícones e temas para compatibilidade com Arch..."

  # Pastas onde o Arch e apps GTK procuram recursos por padrão
  LOCAL_ICONS="$HOME/.local/share/icons"
  LOCAL_THEMES="$HOME/.local/share/themes"

  # Pastas onde o Nix instala os recursos
  NIX_ICONS="$HOME/.nix-profile/share/icons"
  NIX_THEMES="$HOME/.nix-profile/share/themes"

  # 1. Garante que as pastas locais existem
  mkdir -p "$LOCAL_ICONS"
  mkdir -p "$LOCAL_THEMES"

  # 2. Linkar Ícones e Cursors (Papirus, Bibata, etc)
  if [ -d "$NIX_ICONS" ]; then
    log "Linkando pacotes de ícones do perfil Nix..."
    # O ln -sfn (symbolic, force, no-dereference) é ideal para scripts
    for icon_dir in "$NIX_ICONS"/*; do
      if [ -d "$icon_dir" ]; then
        ln -sfn "$icon_dir" "$LOCAL_ICONS/"
      fi
    done
  fi

  # 3. Linkar Temas GTK (Nordic, Tokyonight, Gruvbox)
  if [ -d "$NIX_THEMES" ]; then
    log "Linkando temas GTK do perfil Nix..."
    for theme_dir in "$NIX_THEMES"/*; do
      if [ -d "$theme_dir" ]; then
        ln -sfn "$theme_dir" "$LOCAL_THEMES/"
      fi
    done
  fi

  log "Linkando esquemas de GSettings para o Arch..."
  mkdir -p ~/.local/share/glib-2.0/schemas
  ln -sfn ~/.nix-profile/share/glib-2.0/schemas/* ~/.local/share/glib-2.0/schemas/
  # Compila os esquemas para o sistema os reconhecer imediatamente
  glib-compile-schemas ~/.local/share/glib-2.0/schemas

  # Definir ícones e tema GTK via gsettings (sessão D-Bus; não falha se não houver sessão)
  if command -v /usr/bin/gsettings &>/dev/null; then
    /usr/bin/gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    /usr/bin/gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null || true
  fi

  log "Pontes criadas com sucesso! Thunar e Hyprland agora reconhecem os temas."

  log "Ativando serviços..."
  # Habilitar e iniciar o serviço greetd
  if ! systemctl is-enabled --quiet greetd; then
    sudo systemctl enable greetd
  fi
  sudo systemctl enable --now bluetooth # se tiveres bluetooth
  systemctl --user enable xdg-desktop-portal.service
  systemctl --user enable xdg-desktop-portal-hyprland.service
}

# --- Helpers INI (usados pela etapa 'qt') ---
# ini_get <ficheiro> <secção> <chave>  -> imprime o valor (vazio se não existir)
ini_get() {
  awk -v s="[$2]" -v k="$3" '
    $0==s {ins=1; next}
    /^\[/ {ins=0}
    ins && index($0,k"=")==1 {print substr($0,length(k)+2); exit}
  ' "$1" 2>/dev/null
}

# ini_set <ficheiro> <secção> <chave> <valor>  -> cria/atualiza a chave, preserva o resto
ini_set() {
  local f="$1" s="$2" k="$3" v="$4"
  mkdir -p "$(dirname "$f")"
  touch "$f"
  grep -qxF "[$s]" "$f" || printf '\n[%s]\n' "$s" >> "$f"
  if [ -n "$(awk -v s="[$s]" -v k="$k" '
        $0==s {ins=1; next}
        /^\[/ {ins=0}
        ins && index($0,k"=")==1 {print "x"; exit}' "$f")" ]; then
    awk -v s="[$s]" -v k="$k" -v v="$v" '
      $0==s {ins=1; print; next}
      /^\[/ {ins=0}
      ins && index($0,k"=")==1 {print k"="v; next}
      {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  else
    awk -v s="[$s]" -v k="$k" -v v="$v" '
      {print}
      $0==s {print k"="v}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
}

stage_qt() {
  # ==========================================
  # 11. TEMA QT / KDE (Dolphin e outras apps Qt seguem o Noctalia)
  # ==========================================
  log "Etapa 11 - Tema Qt/KDE (qt6ct-kde + esquema 'noctalia')..."

  local QT_CONF="$HOME/.config/qt6ct/qt6ct.conf"
  local KDEGLOBALS="$HOME/.config/kdeglobals"
  # Ficheiro de cores gerado pelo Noctalia (template 'Qt' do Noctalia)
  local QT_COLORS="$HOME/.config/qt6ct/colors/noctalia.conf"

  # 11.1 Garantir qt6ct-kde (substitui o qt6ct; os dois conflitam)
  if ! pacman -Q qt6ct-kde &>/dev/null; then
    if pacman -Q qt6ct &>/dev/null; then
      warn "A remover 'qt6ct' para o substituir por 'qt6ct-kde'..."
      sudo pacman -Rdd --noconfirm qt6ct
    fi
    yay -S --noconfirm --needed qt6ct-kde
  else
    log "'qt6ct-kde' já instalado."
  fi

  # 11.2 qt6ct.conf: escolher o esquema do Noctalia (sem apagar o resto)
  log "Configurando $QT_CONF..."
  ini_set "$QT_CONF" Appearance color_scheme_path "$QT_COLORS"
  ini_set "$QT_CONF" Appearance custom_palette true
  # Só define estilo e ícones se o utilizador ainda não escolheu
  [ -n "$(ini_get "$QT_CONF" Appearance style)" ]      || ini_set "$QT_CONF" Appearance style Fusion
  ini_set "$QT_CONF" Appearance icon_theme Papirus-Dark

  # 11.3 kdeglobals: apps KDE (Dolphin) leem o esquema daqui
  ini_set "$KDEGLOBALS" General ColorScheme noctalia

  # 11.4 Avisos úteis
  if [ -z "${QT_QPA_PLATFORMTHEME:-}" ]; then
    warn "QT_QPA_PLATFORMTHEME não está definido nesta sessão; confirma que o Hyprland/UWSM exporta QT_QPA_PLATFORMTHEME=qt6ct."
  fi
  if [ ! -f "$QT_COLORS" ]; then
    warn "$QT_COLORS ainda não existe: liga o template 'Qt' no Noctalia e muda o esquema/wallpaper uma vez para o gerar."
  fi
  log "Qt configurado. Reinicia as apps Qt (pkill dolphin; dolphin)."
}

# ==========================================
# EXECUÇÃO
# ==========================================

# Valida pré-requisitos da etapa escolhida (salvo em modo 'all' onde a ordem é linear)
if [[ "$STAGE" != "all" ]]; then
  check_prerequisites
fi

if [[ "$STAGE" == "all" ]]; then
  log ">>> INICIANDO SETUP 'ARCH ETERNO' (execução completa) <<<"
  stage_mirrors
  stage_yay
  stage_packages
  stage_plymouth
  stage_greetd
  stage_cache
  stage_nix
  stage_vscode
  stage_zsh
  stage_themes
  stage_qt
else
  log ">>> INICIANDO SETUP 'ARCH ETERNO' (etapa isolada: $STAGE) <<<"
  case "$STAGE" in
    mirrors)   stage_mirrors ;;
    yay)       stage_yay ;;
    packages)  stage_packages ;;
    plymouth)  stage_plymouth ;;
    greetd)    stage_greetd ;;
    cache)     stage_cache ;;
    nix)       stage_nix ;;
    vscode)    stage_vscode ;;
    zsh)       stage_zsh ;;
    themes)    stage_themes ;;
    qt)        stage_qt ;;
    *)
      err "Etapa desconhecida: $STAGE"
      usage
      exit 1
      ;;
  esac
fi

log ">>> ETAPA CONCLUÍDA! <<<"