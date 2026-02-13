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

log() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
err()  { echo -e "${RED}[X] $1${NC}"; }

trap 'err "Erro na linha $LINENO. Verifique a saída acima."' ERR

log ">>> INICIANDO SETUP 'ARCH ETERNO' (v2 com SDDM + Plymouth) <<<"

# ==========================================
# 1. OTIMIZAÇÃO DE MIRRORS
# ==========================================
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

# ==========================================
# 2. VERIFICAÇÃO DO YAY (AUR HELPER)
# ==========================================
log "Verificando AUR Helper (yay)..."

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

# ==========================================
# 3. ATUALIZAÇÃO E PACOTES BASE
# ==========================================
log "Sincronizando sistema..."
sudo pacman -Syu --noconfirm

log "Instalando pacotes base e interface..."

# Lista unificada (Pacman + AUR via yay)
PKGS=(
    hyprland hyprpaper swaybg xorg-xwayland
    waybar kitty hyprtoolkit hyprlock hypridle
    pipewire pipewire-pulse wireplumber polkit-gnome
    dolphin ttf-jetbrains-mono-nerd rofi-wayland flatpak
    xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
    xdg-desktop-portal
    brightnessctl blueman network-manager-applet swaync
    sddm qt5-quickcontrols2 qt5-graphicaleffects qt5-svg
    podman distrobox podman-compose btop plymouth nmtui-go bluetuith
)

# Usa o yay para instalar tudo (ele lida com pacotes oficiais e AUR simultaneamente)
yay -S --noconfirm --needed "${PKGS[@]}"

# Habilitar Podman Socket
if ! systemctl --user is-active --quiet podman.socket; then
    log "Habilitando Podman Socket..."
    systemctl --user enable --now podman.socket
fi

# ==========================================
# 4. CONFIGURAÇÃO DO PLYMOUTH (NOVO)
# ==========================================
log "Configurando Plymouth (Animação de Boot)..."

# 4.1 Adicionar Hook ao mkinitcpio
if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
    log "Adicionando hook 'plymouth' ao mkinitcpio..."
    # Insere 'plymouth' logo após 'udev' para garantir a ordem correta
    sudo sed -i 's/\(udev\)/\1 plymouth/' /etc/mkinitcpio.conf
else
    log "Hook do Plymouth já configurado."
fi



# 4.2 Configurar GRUB para Boot Silencioso (Quiet Splash)
if [ -f /etc/default/grub ]; then
    if ! grep -q "quiet splash" /etc/default/grub; then
        log "Adicionando 'quiet splash' ao GRUB..."
        # Adiciona os parâmetros à linha GRUB_CMDLINE_LINUX_DEFAULT
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&quiet splash /' /etc/default/grub
        log "Atualizando configuração do GRUB..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
else
    warn "GRUB não encontrado (Systemd-boot?). Adicione 'quiet splash' manualmente ao seu bootloader."
fi

# 4.3 Definir Tema e Gerar Initramfs
log "Aplicando tema 'spinner' e gerando imagem de boot..."
# O flag -R reconstrói o initramfs automaticamente
TARGET_THEME="spinner"
# 1. Verifica qual é o tema atual
CURRENT_THEME=$(plymouth-set-default-theme)

if [ "$CURRENT_THEME" != "$TARGET_THEME" ]; then
    log "Tema do Plymouth diferente de $TARGET_THEME. Atualizando..."
    sudo plymouth-set-default-theme -R "$TARGET_THEME"
else
    log "Plymouth já está configurado como $TARGET_THEME. Ignorando reconstrução do boot."
fi

# ==========================================
# 5. CONFIGURAÇÃO DO DISPLAY MANAGER (SDDM)
# ==========================================
log "Configurando SDDM..."
if ! systemctl is-enabled --quiet sddm; then
    sudo systemctl enable sddm
fi

sudo mkdir -p /etc/sddm.conf.d
echo -e "[Users]\nMinimumUid=1000\nMaximumUid=29000" | sudo tee /etc/sddm.conf.d/hide-nix-users.conf > /dev/null

# ====================================================
# INICIALIZAÇÃO DE CACHE E TEMA
# ====================================================

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

# ==========================================
# 6. INSTALAÇÃO DO NIX & ATIVAÇÃO DE FLAKES
# ==========================================
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

if ! command -v home-manager &> /dev/null; then
    log "Aplicando configuração inicial do Home Manager via Flake..."  
    # Em vez de instalar, corremos diretamente o Home Manager do GitHub
    # para aplicar o teu repositório local.
    # AJUSTE: Garante que o nome após o '#' é o mesmo do teu flake.nix (ex: stardust)
    nix run github:nix-community/home-manager/release-24.11 -- switch --impure --flake ~/arch-install-script/nix/.config/home-manager#stardust
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

# Agora corremos o Home Manager apontando para a pasta exata que contém o flake.nix
log "Iniciando a configuração via Flake em $NIX_CONF_DIR..."

nix run github:nix-community/home-manager/release-24.11 -- switch --impure --flake "$NIX_CONF_DIR#stardust"

# ====================================================
# 4. APLICAÇÃO DO HOME MANAGER (VERSÃO BLINDADA)
# ====================================================
# --- 4. APLICAÇÃO DO HOME MANAGER (VERSÃO FINAL) ---
log "Aplicando Home Manager com suporte a D-Bus..."

export NIXPKGS_ALLOW_UNFREE=1

# O dbus-run-session resolve o erro 'ServiceUnknown'
if command -v dbus-run-session &> /dev/null; then
    dbus-run-session -- home-manager switch -b backup --impure --flake "$NIX_CONF_DIR#stardust"
else
    home-manager switch -b backup --impure --flake "$NIX_CONF_DIR#stardust"
fi


# ==========================================
# 7. CONFIGURAÇÃO DO VS CODE (AUTOMATIZADA)
# ==========================================
log "Instalando e Configurando o VS Code..."

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

# ====================================================
# DEFINIR ZSH DO NIX COMO DEFAULT
# ====================================================

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

# ====================================================
# 7. COMPATIBILIDADE DE TEMAS (NIX -> ARCH BRIDGE)
# ====================================================
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

log "Pontes criadas com sucesso! Thunar e Hyprland agora reconhecem os temas."

log "Ativando serviços..."
sudo systemctl enable --now sddm
sudo systemctl enable --now bluetooth # se tiveres bluetooth
systemctl --user enable xdg-desktop-portal.service
systemctl --user enable xdg-desktop-portal-hyprland.service


log ">>> SETUP CONCLUÍDO! REINICIE O SISTEMA. <<<"