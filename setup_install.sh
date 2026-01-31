#!/bin/bash

# ==========================================
# CONFIGURAÇÃO E VARIÁVEIS
# ==========================================
set -e  # Para o script se houver erro

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/dotfiles"

# Funções de Log
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
        log "Otimizando mirrors (ZA, BR, PT)..."
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
        sudo reflector --country 'South Africa,Brazil,Portugal' --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    fi
else
    log "Instalando Reflector..."
    sudo pacman -Sy --noconfirm --needed reflector
fi

# ==========================================
# 2. ATUALIZAÇÃO E PACOTES BASE
# ==========================================
log "Sincronizando sistema..."
sudo pacman -Syu --noconfirm

log "Instalando pacotes base..."

PKGS=(
    git
    base-devel
    hyprland
    hyprpaper
    swaybg
    xorg-xwayland
    waybar
    dunst
    kitty
    rofi-wayland
    pipewire
    pipewire-pulse
    wireplumber
    polkit-gnome
    thunar
    ttf-jetbrains-mono-nerd
    xdg-desktop-portal-hyprland
    qt5-wayland
    qt6-wayland
    # --- SDDM e Deps ---
    sddm
    qt5-quickcontrols2
    qt5-graphicaleffects
    qt5-svg
    # --- Container ---
    podman
    distrobox
    podman-compose
    stow
    btop
    flatpak
)

sudo pacman -S --noconfirm --needed "${PKGS[@]}"

# Habilitar Podman Socket
if ! systemctl --user is-active --quiet podman.socket; then
    log "Habilitando Podman Socket..."
    systemctl --user enable --now podman.socket
fi

# ==========================================
# 3. CONFIGURAÇÃO DO DISPLAY MANAGER (SDDM)
# ==========================================
log "Configurando SDDM (Tela de Login)..."

# Habilita o serviço do SDDM para iniciar no boot
if ! systemctl is-enabled --quiet sddm; then
    sudo systemctl enable sddm
    log "Serviço SDDM habilitado."
else
    warn "SDDM já estava habilitado."
fi

# Opcional: Criar pasta de temas caso queira instalar um depois
sudo mkdir -p /usr/share/sddm/themes

# FIX: Esconder usuários de build do Nix (ID > 29000)
log "Aplicando correção para esconder usuários Nix do login..."
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Users]\nMinimumUid=1000\nMaximumUid=29000" | sudo tee /etc/sddm.conf.d/hide-nix-users.conf > /dev/null

# ==========================================
# 4. INSTALAÇÃO DO NIX
# ==========================================
if command -v nix &> /dev/null; then
    warn "Nix já está instalado."
else
    log "Instalando Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

# ==========================================
# 5. INSTALAÇÃO DO HOME MANAGER
# ==========================================
if command -v home-manager &> /dev/null; then
    warn "Home Manager já instalado."
else
    log "Configurando Home Manager..."
    if ! nix-channel --list | grep -q "home-manager"; then
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
    fi
    nix-shell '<home-manager>' -A install
fi

# ==========================================
# 6. CONFIGURAÇÃO DE DOTFILES (STOW)
# ==========================================
log "Sincronizando Dotfiles com o sistema..."

# 1. Garante que as pastas de destino existam para o Stow não falhar
mkdir -p "$HOME/.config"

# 2. Prepara o terreno: Se as pastas já existirem e NÃO forem links, faz backup
# Isso evita que o Stow dê erro de "conflito"
prepare_stow() {
    local dir="$1"
    if [ -d "$HOME/$dir" ] && [ ! -L "$HOME/$dir" ]; then
        warn "Pasta $dir real detectada. Movendo para backup..."
        mv "$HOME/$dir" "$HOME/${dir}_backup_$(date +%s)"
    fi
}

prepare_stow ".config/hypr"
prepare_stow ".config/home-manager"

# 3. Executa a mágica do Stow
# O Stow vai linkar as pastas do repo (~/dotfiles/hypr e ~/dotfiles/nix) para o seu $HOME
log "Criando links simbólicos..."
cd "$DOTFILES_DIR"

if [ -d "hypr" ]; then
    stow hypr
    log "Hyprland linkado."
else
    err "Pasta 'hypr' não encontrada no repositório!"
fi

if [ -d "nix" ]; then
    stow nix
    log "Nix/Home-Manager linkado."
else
    err "Pasta 'nix' não encontrada no repositório!"
fi

# ==========================================
# FINALIZAÇÃO
# ==========================================
log ">>> INSTALAÇÃO CONCLUÍDA! <<<"
echo ""
echo "O sistema está pronto."
echo "1. Reinicie: 'sudo reboot'"
echo "2. O login mostrará apenas seu usuário (Nix users ocultos)."
echo "3. No Hyprland, use Super+Q para abrir o terminal."
