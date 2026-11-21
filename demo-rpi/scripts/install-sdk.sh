#!/usr/bin/env bash
# Instaluje SDK z Yocto (toolchain aarch64 + Qt 6) z gotowego instalatora do stałego
# katalogu - dla Qt Creatora i pracy poza repozytorium. Mierzy czas instalacji.
#
#   ./scripts/install-sdk.sh                  # do /opt/poky/6.0.4 (domyślne miejsce SDK Poky)
#   ./scripts/install-sdk.sh ~/sdk/rpi3       # do innego katalogu
#
# Instalator powstaje w ./scripts/build-sdk.sh (bitbake espresso-image -c populate_sdk).
# Katalog SDK w repozytorium (demo-rpi/sdk, używany przez Jenkinsa) zostaje bez zmian.
source "$(dirname "$0")/common.sh"

SDK_DIR="${1:-/opt/poky/6.0.4}"
installer="$(ls -t "$(deploy_dir)"/sdk/*espresso-image*toolchain*.sh 2>/dev/null | head -1 || true)"
[[ -n "$installer" ]] || { echo "Brak instalatora SDK - uruchom ./scripts/build-sdk.sh" >&2; exit 1; }

echo ">> Instalator: $(basename "$installer") ($(du -h "$installer" | cut -f1))"
echo ">> Katalog:    $SDK_DIR"

# Poprzednią instalację usuwamy tylko wtedy, gdy to na pewno SDK (albo pusty katalog)
if [[ -e "$SDK_DIR" ]]; then
    if compgen -G "$SDK_DIR/environment-setup-*" >/dev/null || [[ -z "$(ls -A "$SDK_DIR")" ]]; then
        echo ">> Usuwam poprzednią instalację SDK"
        rm -rf "$SDK_DIR"
    else
        echo "$SDK_DIR istnieje i nie wygląda na SDK - przerywam" >&2
        exit 1
    fi
fi

# Katalog nadrzędny (np. /opt/poky) należy do Ciebie, więc SDK nie będzie należeć do roota
parent="$(dirname "$SDK_DIR")"
if [[ ! -w "$parent" ]]; then
    sudo mkdir -p "$parent"
    sudo chown "$USER": "$parent"
fi

start=$(date +%s)
# -y: bez pytań, -d: katalog docelowy (instalator "przypina" SDK do tej ścieżki -
# po przeniesieniu katalogu trzeba zainstalować ponownie)
"$installer" -y -d "$SDK_DIR"
end=$(date +%s)

echo
echo ">> Czas instalacji: $(( end - start )) s"
echo ">> Rozmiar SDK:     $(du -sh "$SDK_DIR" | cut -f1)"
echo ">> Dla Qt Creatora (plik toolchaina CMake bez zmiennych środowiskowych):"
echo "   $SDK_DIR/sysroots/x86_64-pokysdk-linux/usr/share/cmake/Qt6Toolchain.cmake"
