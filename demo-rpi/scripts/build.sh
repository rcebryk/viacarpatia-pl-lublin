#!/usr/bin/env bash
# Buduje cały obraz systemu (pierwszy raz: kilka godzin, potem minuty).
# Użycie: ./scripts/build.sh            - obraz espresso-image
#         ./scripts/build.sh espresso-hmi  - tylko aplikacja
source "$(dirname "$0")/common.sh"
ensure_kas
cd "$REPO"

start=$(date +%s)
if [[ $# -gt 0 ]]; then
    "$KAS_CONTAINER" shell "$KAS_FILE" -c "bitbake $*"
else
    "$KAS_CONTAINER" build "$KAS_FILE"
fi
end=$(date +%s)

echo
echo ">> Czas buildu: $(( (end - start) / 60 )) min $(( (end - start) % 60 )) s"
ls -lh "$(deploy_dir)/images/raspberrypi3-64/"espresso-image-raspberrypi3-64.rootfs.wic.* 2>/dev/null || true
