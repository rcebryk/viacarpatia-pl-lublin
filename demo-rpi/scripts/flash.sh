#!/usr/bin/env bash
# Zapis obrazu na kartę SD.  Użycie: ./scripts/flash.sh /dev/sdX
source "$(dirname "$0")/common.sh"

dev="${1:-}"
if [[ -z "$dev" || ! -b "$dev" ]]; then
    echo "Użycie: $0 /dev/sdX   (sprawdź urządzenie: lsblk)" >&2
    lsblk -d -o NAME,SIZE,TRAN,MODEL >&2
    exit 1
fi
if [[ "$(lsblk -dno TRAN "$dev")" != "usb" && "$dev" != /dev/mmcblk* ]]; then
    echo "$dev nie wygląda na czytnik kart (USB/MMC) - przerywam dla bezpieczeństwa" >&2
    exit 1
fi

img_dir="$(deploy_dir)/images/raspberrypi3-64"
img="$img_dir/espresso-image-raspberrypi3-64.rootfs.wic.bz2"
bmap="$img_dir/espresso-image-raspberrypi3-64.rootfs.wic.bmap"
[[ -f "$img" ]] || { echo "Brak obrazu $img - uruchom ./scripts/build.sh" >&2; exit 1; }

lsblk "$dev"
read -r -p "Wszystkie dane na $dev zostaną skasowane. Kontynuować? [t/N] " ans
[[ "$ans" == "t" || "$ans" == "T" ]] || exit 1

sudo umount "$dev"?* 2>/dev/null || true
if command -v bmaptool >/dev/null; then
    sudo bmaptool copy --bmap "$bmap" "$img" "$dev"
else
    echo ">> bmaptool niedostępny (dnf install bmap-tools) - używam dd"
    bzcat "$img" | sudo dd of="$dev" bs=4M conv=fsync status=progress
fi
sync
echo ">> Karta gotowa"
