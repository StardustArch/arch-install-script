#!/bin/bash

# Configurações
WALL_DIR="$HOME/.config/hypr/wallpapers"
INTERVAL=${2:-300} # Padrão: 5 minutos se não especificado

# Garante que o hyprpaper está rodando
if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
    sleep 1
fi

# Função para aplicar o wallpaper
apply_wall() {
    local wall=$1
    # Preload e Set (ajuste 'eDP-1' para o nome do seu monitor se necessário)
    hyprctl hyprpaper preload "$wall"
    hyprctl hyprpaper wallpaper "monitor,$wall"
    # Limpa o cache para não estourar a RAM
    hyprctl hyprpaper unload all
}

case $1 in
    "static")
        # Seleciona um aleatório e para por aí
        SELECTED=$(find "$WALL_DIR" -type f | shuf -n 1)
        apply_wall "$SELECTED"
        ;;
    "loop")
        # Mata loops anteriores para não duplicar
        pkill -f "wall.sh loop" || true
        log "Iniciando loop de $INTERVAL segundos..."
        while true; do
            SELECTED=$(find "$WALL_DIR" -type f | shuf -n 1)
            apply_wall "$SELECTED"
            sleep "$INTERVAL"
        done
        ;;
    *)
        echo "Uso: wall.sh {static|loop [segundos]}"
        ;;
esac