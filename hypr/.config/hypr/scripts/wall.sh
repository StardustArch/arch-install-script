#!/bin/bash

# --- CONFIGURAÇÃO ---
WALL_DIR="$HOME/.config/hypr/wallpapers"
INTERVAL=${2:-300} # 300s = 5 minutos
BACKEND="hyprpaper" # Padrão inicial

# --- 1. VERIFICAÇÃO INTELIGENTE DO BACKEND ---

# Tenta iniciar o hyprpaper se não estiver rodando
if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
    sleep 1
fi

# Teste de conexão: Tenta falar com o hyprpaper
# Se der erro (ex: VM sem GPU), define o backend para swaybg
if ! hyprctl hyprpaper listloaded > /dev/null 2>&1; then
    echo "⚠️  Hyprpaper falhou (VM sem GPU?). Alternando para swaybg."
    pkill hyprpaper 2>/dev/null
    BACKEND="swaybg"
else
    # Se o hyprpaper respondeu, tenta pegar o monitor
    MONITOR=$(hyprctl monitors | grep "Monitor" | awk '{print $2}' | head -n 1)
    if [ -z "$MONITOR" ]; then
        echo "⚠️  Monitor não detectado para hyprpaper. Alternando para swaybg."
        BACKEND="swaybg"
    fi
fi

# Se caiu no fallback, verifica se tem o swaybg instalado
if [ "$BACKEND" == "swaybg" ] && ! command -v swaybg &> /dev/null; then
    echo "❌ Erro Crítico: Hyprpaper falhou e swaybg não está instalado."
    echo "Instale com: sudo pacman -S swaybg"
    exit 1
fi

# --- 2. FUNÇÃO UNIFICADA DE APLICAÇÃO ---
apply_wall() {
    local wall="$1"
    
    if [ -z "$wall" ]; then
        echo "Erro: Nenhum wallpaper encontrado em $WALL_DIR"
        return
    fi

    if [ "$BACKEND" == "hyprpaper" ]; then
        echo "🎨 [Hyprpaper] Aplicando: $(basename "$wall")"
        hyprctl hyprpaper preload "$wall"
        hyprctl hyprpaper wallpaper "$MONITOR,$wall"
        hyprctl hyprpaper unload unused
        
    elif [ "$BACKEND" == "swaybg" ]; then
        echo "🎨 [SwayBG] Aplicando: $(basename "$wall")"
        # Mata o anterior e inicia o novo em background
        pkill swaybg
        swaybg -i "$wall" -m fill &
    fi
}

# --- 3. LÓGICA DE EXECUÇÃO (LOOP OU ESTÁTICO) ---
case $1 in
    "static")
        # Mata loop anterior para evitar conflito
        pkill -f "wall.sh loop" || true
        
        # Seleciona um wallpaper aleatório
        SELECTED=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | shuf -n 1)
        apply_wall "$SELECTED"
        ;;
        
    "loop")
        # Garante que não existem dois scripts rodando ao mesmo tempo
        if pgrep -f "wall.sh loop" | grep -v $$ > /dev/null; then
            echo "Loop de wallpaper já está rodando."
            exit 0
        fi
        
        echo "Iniciando loop ($INTERVAL segundos) usando backend: $BACKEND"
        
        while true; do
            SELECTED=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | shuf -n 1)
            apply_wall "$SELECTED"
            sleep "$INTERVAL"
        done
        ;;
        
    *)
        echo "Uso: wall.sh {static|loop [segundos]}"
        exit 1
        ;;
esac