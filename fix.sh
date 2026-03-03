#!/usr/bin/env bash
set -euo pipefail

echo
echo "==> Baixando wallpapers enviados..."

WALLDIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLDIR"

# Baixa cada wallpaper
curl -L -o "$WALLDIR/lofi-1.png" https://images4.alphacoders.com/132/thumb-1920-1321259.png
curl -L -o "$WALLDIR/lofi-2.webp" https://images5.alphacoders.com/133/thumbbig-1338843.webp
curl -L -o "$WALLDIR/lofi-3.webp" https://images4.alphacoders.com/138/thumbbig-1385287.webp
curl -L -o "$WALLDIR/lofi-4.webp" https://images5.alphacoders.com/134/thumbbig-1344548.webp

echo "==> Wallpapers salvos em: $WALLDIR"

echo
echo "==> Instalando python-pywal e convert (caso falte)..."
sudo pacman -S --needed python-pywal imagemagick

echo
echo "==> Gerando cores com pywal usando o primeiro wallpaper..."
wal -i "$WALLDIR/lofi-1.png"

echo
echo "==> Verificando cache wal..."
if [[ ! -d "$HOME/.cache/wal" ]]; then
    echo "[!] Wal não gerou cache. Verifique se o wal rodou sem erro."
else
    echo "Wal cache ok:"
    ls -l ~/.cache/wal | sed -n '1,5p'
fi

echo
echo "==> Ajustando Polybar para usar o arquivo generated..."

POLYFILE="$HOME/.config/polybar/config.ini"
if grep -q "include-file" "$POLYFILE"; then
    echo "Polybar config já contém include-file"
else
    echo "Incluindo colors-polybar no topo do config"
    sed -i '1s|^|include-file = ~/.cache/wal/colors-polybar\n|' "$POLYFILE"
fi

echo
echo "==> Wallpapers prontos e pywal aplicado!"
echo "Você pode rodar a polybar manual:"
echo "   ~/.config/polybar/launch.sh"
echo
echo "Ou reiniciar a sessão do i3 para aplicar automaticamente!"
