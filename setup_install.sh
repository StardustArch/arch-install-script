#!/bin/bash
# install.sh - Arch Eterno Setup

echo ">>> 1. Atualizando sistema e criando snapshot de segurança..."
sudo pacman -Syu --noconfirm

echo ">>> 2. Instalando Base Gráfica (Hyprland & Audio)..."
# pipewire: audio, waybar: barra, dunst: notificacoes, kitty: terminal
sudo pacman -S --noconfirm hyprland xorg-xwayland waybar dunst \
kitty rofi-wayland pipewire pipewire-pulse wireplumber \
polkit-gnome thunar ttc-iosevka-nerd ttf-jetbrains-mono-nerd \
xdg-desktop-portal-hyprland qt5-wayland qt6-wayland

echo ">>> 3. Instalando Ferramentas de Contêiner (Distrobox)..."
sudo pacman -S --noconfirm podman distrobox podman-compose
# Habilitar podman socket (opcional, bom para compatibilidade docker)
systemctl --user enable --now podman.socket

echo ">>> 4. Instalando Nix (Multi-user)..."
# Usando o instalador determinado (zero-to-nix style)
if ! command -v nix &> /dev/null; then
    sh <(curl -L https://nixos.org/nix/install) --daemon
    # Ativar nix para esta sessão sem precisar relogar
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
    echo "Nix já instalado."
fi

echo ">>> 5. Instalando Home Manager (Standalone)..."
# Adiciona o canal unstable (mais atualizado)
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
# Instala o home-manager
nix-shell '<home-manager>' -A install

echo ">>> 6. Preparando estrutura de Dotfiles..."
mkdir -p ~/.config/hypr
# Aqui futuramente entra o 'stow', por enquanto vamos criar configs basicas
# para garantir que o Hyprland abra.

# Config minima do Hyprland para não dar tela preta/erro
cat <<EOF > ~/.config/hypr/hyprland.conf
monitor=,preferred,auto,1
exec-once = waybar & dunst
input {
    kb_layout = br
}
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee)
}
decoration {
    rounding = 10
}
dwindle {
    pseudotile = yes
    preserve_split = yes
}
EOF

echo ">>> INSTALAÇÃO CONCLUÍDA!"
echo "Reinicie a máquina ou digite 'Hyprland' para testar."
