#!/bin/bash

# Importa as cores do Rofi (opcional, ele usará seu config.rasi padrão)
toggle_wifi() {
    state=$(nmcli -fields WIFI g | tail -n 1 | awk '{print $1}')
    if [ "$state" = "enabled" ]; then
        nmcli radio wifi off
    else
        nmcli radio wifi on
    fi
}

# Lista redes disponíveis
list_networks() {
    nmcli -t -f "SSID,SECURITY,BARS" device wifi list | sed 's/\\:/%%/g' | awk -F: '{print $3 " " $1}' | sed 's/%%/:/g'
}

# Menu Rofi
chosen_network=$(printf "OFF/ON Wi-Fi\n$(list_networks)" | rofi -dmenu -i -p "󰖩 Wi-Fi" -config ~/.config/rofi/config.rasi)

if [ "$chosen_network" = "OFF/ON Wi-Fi" ]; then
    toggle_wifi
elif [ -n "$chosen_network" ]; then
    # Pega apenas o SSID (remove os ícones de sinal se houver)
    ssid=$(echo "$chosen_network" | awk '{print $2}')
    # Tenta conectar (vai pedir senha via GUI se necessário)
    nmcli device wifi connect "$ssid"
fi