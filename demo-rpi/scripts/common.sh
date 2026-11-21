# Wspólne ustawienia dla skryptów (dołączane przez "source")
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KAS_VERSION="5.5"
KAS_CONTAINER="$REPO/tools/kas-container"
KAS_FILE="kas/rpi3-qt6.yml"

# Silnik kontenerów: domyślnie Docker; Podman: KAS_CONTAINER_ENGINE=podman ./scripts/build.sh
export KAS_CONTAINER_ENGINE="${KAS_CONTAINER_ENGINE:-docker}"
# SELinux (Fedora): bez tego kontener nie może czytać montowanych katalogów.
# Dla Podmana kas-container dodaje tę opcję sam, dla Dockera - nie.
export KAS_RUNTIME_ARGS="${KAS_RUNTIME_ARGS:---security-opt label=disable}"
# Katalogi robocze buildu (poza kodem źródłowym)
export KAS_WORK_DIR="${KAS_WORK_DIR:-$REPO/build}"
# Pobrane źródła i cache sstate - współdzielone między projektami,
# dzięki nim kolejny build trwa minuty, a nie godziny
export DL_DIR="${DL_DIR:-$HOME/yocto-cache/downloads}"
export SSTATE_DIR="${SSTATE_DIR:-$HOME/yocto-cache/sstate-cache}"

# Adres RPi przy połączeniu kablem bezpośrednio z laptopem
TARGET="${TARGET:-root@192.168.77.2}"
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

ensure_kas() {
    if [[ "$KAS_CONTAINER_ENGINE" == docker ]] && ! docker info >/dev/null 2>&1; then
        echo "Docker nie odpowiada: usługa nie działa (sudo systemctl enable --now docker)" >&2
        echo "albo brak uprawnień (sudo usermod -aG docker \$USER, potem wyloguj się i zaloguj)." >&2
        echo "Podman zamiast Dockera: KAS_CONTAINER_ENGINE=podman $0" >&2
        exit 1
    fi
    mkdir -p "$KAS_WORK_DIR" "$DL_DIR" "$SSTATE_DIR" "$(dirname "$KAS_CONTAINER")"
    if [[ ! -x "$KAS_CONTAINER" ]]; then
        echo ">> Pobieram kas-container $KAS_VERSION"
        curl -fsSL -o "$KAS_CONTAINER" \
            "https://raw.githubusercontent.com/siemens/kas/$KAS_VERSION/kas-container"
        chmod +x "$KAS_CONTAINER"
    fi
}

# RPi 3 nie ma zegara z baterią, a przy kablu prosto do laptopa nie ma też
# serwera czasu (NTP). Bez tego zegar w aplikacji i daty w journalctl są błędne.
sync_time() {
    ssh "${SSH_OPTS[@]}" "$TARGET" "date -u -s '$(date -u '+%Y-%m-%d %H:%M:%S')' >/dev/null" \
        && echo ">> Zegar RPi ustawiony z laptopa"
}

deploy_dir() {
    echo "$KAS_WORK_DIR/build/tmp/deploy"
}
