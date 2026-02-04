#!/bin/bash

# Verifica se o bluetooth está ligado
power_state=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$power_state" ]; then
    action=$(printf "Ligar Bluetooth\nSair" | rofi -dmenu -p " Bluetooth" -config ~/.config/rofi/config.rasi)
    if [ "$action" = "Ligar Bluetooth" ]; then
        bluetoothctl power on
    fi
    exit 0
fi

# Lista dispositivos pareados
devices=$(bluetoothctl devices Paired | awk '{print $3}')

chosen_device=$(printf "Desligar\nScan\n$devices" | rofi -dmenu -p " Bluetooth" -config ~/.config/rofi/config.rasi)

case "$chosen_device" in
    "Desligar") bluetoothctl power off ;;
    "Scan") kitty -e bluetoothctl scan on ;;
    "") exit 0 ;;
    *) bluetoothctl connect $(bluetoothctl devices Paired | grep "$chosen_device" | awk '{print $2}') ;;
esac