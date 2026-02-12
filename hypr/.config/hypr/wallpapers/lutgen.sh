#!/bin/bash

mkdir -p aizome_ready

# --- PALETAS ---

declare -A AIZOME=(
  [bg0]="101d31" [bg1]="16263e" [bg2]="2b507e" [bg3]="3b4b64"
  [fg0]="dcdcdc" [fg1]="e2e2e2" [fg2]="ffffff"
  [accent0]="7d563e" [accent1]="9a6b4d" [accent2]="3d6a9e" [accent3]="244066"
  [red]="a65e6a" [orange]="c4a068" [yellow]="ad8f5e"
  [green]="8a9a7b" [purple]="7c6a8a"
)

declare -A NORD=(
  [bg0]="2e3440" [bg1]="3b4252" [bg2]="434c5e" [bg3]="4c566a"
  [fg0]="d8dee9" [fg1]="e5e9f0" [fg2]="eceff4"
  [accent0]="8fbcbb" [accent1]="88c0d0" [accent2]="81a1c1" [accent3]="5e81ac"
  [red]="bf616a" [orange]="d08770" [yellow]="ebcb8b"
  [green]="a3be8c" [purple]="b48ead"
)

declare -A GRUVBOX=(
  [bg0]="282828" [bg1]="32302f" [bg2]="45403d" [bg3]="5a524c"
  [fg0]="dfbf8e" [fg1]="d4be98" [fg2]="ddc7a1"
  [accent0]="a9b665" [accent1]="d8a657" [accent2]="7daea3" [accent3]="89b482"
  [red]="ea6962" [orange]="e78a4e" [yellow]="d8a657"
  [green]="a9b665" [purple]="d3869b"
)

# --- MENU ---

echo "Escolhe a paleta:"
echo "1) Aizome"
echo "2) Nord"
echo "3) Gruvbox"
read -p "Opção: " escolha

case $escolha in
  1) PALETA=("${AIZOME[@]}"); nome="aizome" ;;
  2) PALETA=("${NORD[@]}"); nome="nord" ;;
  3) PALETA=("${GRUVBOX[@]}"); nome="gruvbox" ;;
  *) echo "Opção inválida."; exit 1 ;;
esac

echo "A gerar LUT $nome..."

lutgen generate -o "$nome.png" -- "${PALETA[@]}"

[ -f "$nome.png" ] || { echo "Falha ao gerar LUT"; exit 1; }

echo "A aplicar paleta $nome..."

for img in *.jpg *.jpeg *.png *.webp; do
  [ -e "$img" ] || continue
  echo "Processando: $img"
  lutgen apply --hald-clut "$nome.png" "$img" -o "aizome_ready/$img"
done

echo "Feito! Verifica a pasta 'aizome_ready'."
