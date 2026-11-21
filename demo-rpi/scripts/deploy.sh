#!/usr/bin/env bash
# DEMO NA ŻYWO: cross-kompilacja aplikacji w SDK i wdrożenie na RPi.
#   1. cmake + kompilator aarch64 z SDK (sekundy, nie godziny)
#   2. scp binarki na maszynę
#   3. restart usługi systemd
source "$(dirname "$0")/common.sh"

if [[ ! -d "$REPO/sdk" ]]; then
    echo "Brak SDK - uruchom najpierw ./scripts/build-sdk.sh" >&2
    exit 1
fi

# Środowisko SDK ustawia CC/CXX, sysroot itd. (nie jest zgodne z "set -u")
set +u
# shellcheck disable=SC1090
source "$REPO"/sdk/environment-setup-*
set -u

BUILD="$REPO/build-app"
echo ">> Cross-kompilacja ($OECORE_TARGET_ARCH)"
cmake -S "$REPO/../app/espresso-hmi" -B "$BUILD" \
      -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
      -DCMAKE_BUILD_TYPE=Release -DESPRESSO_BUILD_TESTS=OFF
cmake --build "$BUILD"
file "$BUILD/espresso-hmi"

echo ">> Wdrażanie na $TARGET"
sync_time
# plik obok docelowego + mv = atomowa podmiana (ten sam system plików);
# minimalny obraz nie ma polecenia "install"
scp "${SSH_OPTS[@]}" "$BUILD/espresso-hmi" "$TARGET:/usr/bin/espresso-hmi.new"
ssh "${SSH_OPTS[@]}" "$TARGET" '
    chmod 0755 /usr/bin/espresso-hmi.new &&
    mv /usr/bin/espresso-hmi.new /usr/bin/espresso-hmi &&
    systemctl restart espresso-hmi &&
    sleep 2 &&
    systemctl --no-pager --lines=5 status espresso-hmi'
echo ">> Gotowe"
