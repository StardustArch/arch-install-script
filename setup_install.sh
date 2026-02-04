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

log ">>> INICIANDO SETUP 'ARCH ETERNO' (v2 com SDDM) <<<"

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
    waybar kitty rofi-wayland 
    pipewire pipewire-pulse wireplumber polkit-gnome
    thunar ttf-jetbrains-mono-nerd
    xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
    brightnessctl blueman network-manager-applet swaync
    sddm qt5-quickcontrols2 qt5-graphicaleffects qt5-svg
    podman distrobox podman-compose stow btop flatpak
    # --- Adições de Estética ---
    nwg-look                # Gerenciador de Temas GTK
    bibata-cursor-theme     # O cursor que você gosta
    papirus-icon-theme      # Ícones consistentes
)

# Usa o yay para instalar tudo (ele lida com pacotes oficiais e AUR simultaneamente)
yay -S --noconfirm --needed "${PKGS[@]}"

# Habilitar Podman Socket
if ! systemctl --user is-active --quiet podman.socket; then
    log "Habilitando Podman Socket..."
    systemctl --user enable --now podman.socket
fi

# ==========================================
# 4. CONFIGURAÇÃO DO DISPLAY MANAGER (SDDM)
# ==========================================
log "Configurando SDDM..."
if ! systemctl is-enabled --quiet sddm; then
    sudo systemctl enable sddm
fi

sudo mkdir -p /etc/sddm.conf.d
echo -e "[Users]\nMinimumUid=1000\nMaximumUid=29000" | sudo tee /etc/sddm.conf.d/hide-nix-users.conf > /dev/null

# ==========================================
# 5. INSTALAÇÃO DO NIX & ATIVAÇÃO DE FLAKES
# ==========================================
if ! command -v nix &> /dev/null; then
    log "Instalando Nix (via Determinate Systems)..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    
    # Carrega o Nix na sessão atual do script
    [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

log "Habilitando suporte a Flakes..."
mkdir -p ~/.config/nix
# Verifica se a linha já existe para não duplicar
if ! grep -q "flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

if ! command -v home-manager &> /dev/null; then
    log "Instalando Home Manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
fi


# ==========================================
# 6. CONFIGURAÇÃO DE DOTFILES (STOW)
# ==========================================
log "Sincronizando Dotfiles..."
mkdir -p "$HOME/.config"

prepare_stow() {
    local dir="$1"
    if [ -d "$HOME/$dir" ] && [ ! -L "$HOME/$dir" ]; then
        warn "Pasta $dir real detectada. Fazendo backup..."
        mv "$HOME/$dir" "$HOME/${dir}_backup_$(date +%s)"
    fi
}

# Prepara as pastas para o Stow não conflitar
for folder in "hypr" "waybar" "kitty" "rofi" "swaync"; do
    prepare_stow ".config/$folder"
done

cd "$DOTFILES_DIR"
# Linka tudo que estiver no diretório de dotfiles
for folder in */; do
    stow "${folder%/}"
    log "Linkado: ${folder%/}"
done

# ==========================================
# APLICAÇÃO INICIAL DO FLAKE
# ==========================================
# Se os arquivos já foram linkados pelo Stow, rodamos o switch
if [ -f "$HOME/.config/home-manager/flake.nix" ]; then
    log "Aplicando configuração inicial do Home Manager via Flake..."
    # Usando paulo_ como definido no teu home.nix
    home-manager switch --flake "$HOME/.config/home-manager#paulo_"
fi



log ">>> SETUP CONCLUÍDO! REINICIE O SISTEMA. <<<"