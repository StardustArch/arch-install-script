#!/bin/bash

# --- CONFIGURAÇÃO ---
WALL_DIR="$HOME/.config/hypr/wallpapers"
INTERVAL=${2:-300} # 300s = 5 minutos

# 1. Detecta o monitor automaticamente (Resolve o erro da VM)
MONITOR=$(hyprctl monitors | grep "Monitor" | awk '{print $2}' | head -n 1)

if [ -z "$MONITOR" ]; then
    echo "Erro: Nenhum monitor detectado."
    exit 1
fi

# 2. Inicia o hyprpaper se não estiver rodando
if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
    sleep 2
fi

# Função para aplicar wallpaper
apply_wall() {
    local wall="$1"
    echo "Aplicando: $wall no monitor: $MONITOR"
    
    hyprctl hyprpaper preload "$wall"
    hyprctl hyprpaper wallpaper "$MONITOR,$wall"
    
    # Remove wallpapers antigos da RAM (exceto o atual)
    hyprctl hyprpaper unload unused
}

# --- LÓGICA DE MODOS ---
case $1 in
    "static")
        # Mata o loop se existir
        pkill -f "wall.sh loop" || true
        # Escolhe um aleatório
        SELECTED=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
        apply_wall "$SELECTED"
        ;;
        
    "loop")
        # Garante que não tenha 2 loops rodando
        if pgrep -f "wall.sh loop" | grep -v $$ > /dev/null; then
            echo "Loop já está rodando."
            exit 0
        fi
        
        while true; do
            SELECTED=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
            apply_wall "$SELECTED"
            sleep "$INTERVAL"
        done
        ;;
        
    *)
        echo "Uso: wall.sh {static|loop [segundos]}"
        exit 1
        ;;
esac